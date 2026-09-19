<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\NarrowsDesignTickets;
use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\DesignTicket\AssignDesignTicketRequest;
use App\Application\Api\V1\Requests\DesignTicket\CancelDesignTicketRequest;
use App\Application\Api\V1\Requests\DesignTicket\ReviewDesignVersionRequest;
use App\Application\Api\V1\Requests\DesignTicket\StoreDesignTicketAttachmentRequest;
use App\Application\Api\V1\Requests\DesignTicket\StoreDesignTicketRequest;
use App\Application\Api\V1\Requests\DesignTicket\SubmitDesignVersionRequest;
use App\Application\Api\V1\Requests\DesignTicket\UpdateDesignTicketRequest;
use App\Application\Api\V1\Resources\DesignTicketFileResource;
use App\Application\Api\V1\Resources\DesignTicketResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\DesignTicket\DesignTicketService;
use App\Domain\DesignTicket\DTOs\DesignTicketData;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\DesignTicket\Queries\DesignTicketFilters;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use App\Support\ResponseTrait;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

/**
 * Design tickets
 *
 * A request for artwork, from the employee who asks to the designer who draws it and back again
 * until somebody approves. `new → in_progress → under_review → completed`, with «تعديل مطلوب»
 * looping as many times as it takes — and an approval writing the artwork onto the customer's
 * account, where every future order can reach it.
 *
 * **There is no endpoint that sets a status.** Each one is written by the action that earns it:
 * accepting, submitting, reviewing, cancelling. A status a client could choose would let a ticket
 * claim it was accepted with nobody's name against it. See `DesignTicketStatus`.
 *
 * Reading needs `design_tickets.view`, which is **narrow**: without `design_tickets.view_all` a
 * reader sees the tickets they raised, the ones addressed to them, the ones they took, and the
 * unclaimed pool. Anything else is a 404 rather than a 403 — a reader has no business learning
 * that a colleague's ticket exists.
 *
 * Writing splits five ways, on the same reasoning that split `shortages.*`: `manage` to raise and
 * edit one, `assign` to route it, `accept` and `submit` for the designer, and `review` for the
 * verdict. **`review` is never granted to the designer role, and that is only half the rule** —
 * the domain refuses a reviewer who is the uploader, because an administrator holds every
 * permission by rule and no roles screen can reach them.
 *
 * No destroy route. A ticket that should not have been raised is **cancelled**, with a reason, so
 * the record of the request survives — see {@see cancel()}.
 */
class DesignTicketController extends Controller
{
    use NarrowsDesignTickets, ReadsAuditTrail, ResponseTrait;

    public function __construct(
        private readonly DesignTicketService $tickets,
        // الشارةُ على كلِّ صفّ تُقرأ من صفوف الإشعارات، وهي سياقٌ آخر — فتُسأل من بابها.
        // والاتّجاه يبقى صحيحاً: الطبقةُ التطبيقيّة تعرف السياقين، ولا يعرف أحدُهما الآخر.
        private readonly NotificationService $notifications,
    ) {}

    /**
     * List design tickets
     *
     * Newest first. Filter with `status` (repeatable), `designer`, `requested_by`, `customer_id`
     * and `order_id`, and narrow with `search` — the ticket's title, its code, or the customer's
     * name.
     *
     * `designer=me` is the designer's own queue and `designer=none` is the shared pool: work
     * addressed to nobody that nobody has taken. Both are words rather than ids because neither is
     * one — «me» is only known here, and «none» is a null a query string cannot otherwise carry.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $this->filtersFrom($request);
        $perPage = min(max((int) $request->integer('per_page', 15), 1), 100);

        $tickets = $this->tickets->paginate($filters, $perPage);
        $this->stampUnreadComments($request, $tickets->getCollection());

        return $this->successWithPagination(DesignTicketResource::collection($tickets));
    }

    /**
     * Design tickets by status
     *
     * How many stand in each status, under the same filters the list takes — what the chip row is
     * drawn from, in one call rather than one per status.
     *
     * Every status is present, zeros included: a missing key would leave the caller choosing
     * between a blank and a zero, and those mean different things.
     *
     * `status` is accepted and ignored, so a screen may hand over its whole filter without
     * stripping the one field that would make every chip but one read zero.
     */
    public function statusCounts(Request $request): JsonResponse
    {
        $counts = $this->tickets->statusCounts($this->filtersFrom($request));

        return $this->success(['counts' => $counts, 'total' => array_sum($counts)]);
    }

    /**
     * Raise a design ticket
     *
     * The customer is required; the order is not — a customer asks for a business card long
     * before they order any bags.
     *
     * `assigned_designer_id` is optional and **null means the shared pool**, which is a real
     * answer rather than a missing one: an employee who does not know who is free leaves it empty,
     * every designer is told, and the first to accept claims it. Naming a designer needs
     * `design_tickets.assign` on top — routing work is a different job from asking for it.
     *
     * Attachments are uploaded separately, so a ticket is never lost to a failed upload.
     */
    public function store(StoreDesignTicketRequest $request): JsonResponse
    {
        $data = $request->validated();

        // Silently dropped rather than refused with a 403. Naming a designer is a *preference* on
        // a request that is otherwise entirely valid, and rejecting the whole ticket would lose
        // the employee's typing over a field they may not even have seen. Unassigned is the
        // correct fallback: every designer is told, and the first to accept takes it.
        if ($request->user()?->can(PermissionName::AssignDesignTickets->value) !== true) {
            unset($data['assigned_designer_id']);
        }

        $ticket = $this->tickets->create(DesignTicketData::fromArray($data), $request->user());

        return $this->created(
            new DesignTicketResource($this->loadForDisplay($request, $ticket)),
            'تم إرسال طلب التصميم',
        );
    }

    /**
     * Show a design ticket
     *
     * With its brief, every attachment, and every version ever uploaded — including the ones that
     * were turned back, each with the note saying why. Nothing is ever removed from that list;
     * that is what «الاحتفاظ بجميع نسخ التصميم السابقة» means.
     */
    public function show(Request $request, DesignTicket $ticket): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        return $this->success(new DesignTicketResource($this->loadForDisplay($request, $ticket)));
    }

    /**
     * Update a design ticket
     *
     * The title, the brief and the instructions, while the ticket is open. **The customer cannot
     * be changed** — files and a conversation hang off a ticket by the time anybody notices the
     * wrong one was picked, so a mis-addressed ticket is cancelled and raised again, which leaves
     * an honest record. The designer is `PATCH /designer`, behind its own grant.
     */
    public function update(UpdateDesignTicketRequest $request, DesignTicket $ticket): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $updated = $this->tickets->update($ticket, $request->validated());

        return $this->success(
            new DesignTicketResource($this->loadForDisplay($request, $updated)),
            'تم تحديث الطلب',
        );
    }

    /**
     * Assign a design ticket
     *
     * Send `assigned_designer_id: null` to return it to the shared pool — the field must be
     * present either way, so an omission is a mistake rather than an instruction.
     *
     * **It does not change the status.** A ticket addressed to somebody who has not yet said yes
     * is still «جديد»: the claim that work has started is the designer's to make by accepting, not
     * a supervisor's to make by routing. And reassigning after acceptance does not rewrite who did
     * the work — `accepted_by` is a record of what happened.
     */
    public function assign(AssignDesignTicketRequest $request, DesignTicket $ticket): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $designerId = $request->validated('assigned_designer_id');

        $updated = $this->tickets->assign(
            $ticket,
            $designerId === null ? null : User::query()->findOrFail($designerId),
            $request->user(),
        );

        return $this->success(
            new DesignTicketResource($this->loadForDisplay($request, $updated)),
            $designerId === null ? 'تم إرجاع التذكرة إلى الطابور المشترك' : 'تم إسناد التذكرة',
        );
    }

    /**
     * Accept a design ticket
     *
     * «قبول الطلب» — the designer says they have it, and the ticket moves to «قيد التصميم».
     *
     * **Exactly one acceptance is possible.** Two designers tapping this on a pool ticket at the
     * same moment are settled by the database, not by a check, and the one who loses is told who
     * holds it. That is «منع عمل أكثر من شخص عليه» made mechanical rather than procedural.
     *
     * A ticket addressed to a named designer is refused to everybody else; one addressed to nobody
     * belongs to whoever reaches it first.
     */
    public function accept(Request $request, DesignTicket $ticket): JsonResponse
    {
        // **Deliberately not `refuseUnlessVisible()`, and this is the one endpoint that differs.**
        //
        // Two designers watching the same pool ticket both tap «قبول». The instant the first one
        // wins, the second's read of `isVisibleTo()` turns false — the ticket is no longer
        // unclaimed and was never theirs — so the strict guard would answer 404 and the loser
        // would be told that the ticket they were looking at a second ago does not exist.
        //
        // That is the opposite of what this step is for. «لا تضيع هوية المصمم الذي استلم الطلب»
        // has a second half: the designer who lost needs to know *whom to talk to*, which is
        // exactly what `DesignTicketAlreadyAccepted` says. So an **open** ticket is answered by
        // the domain, which refuses it in words.
        //
        // The narrowing is not abandoned, only moved: a **closed** ticket that is none of this
        // reader's business is still a 404, so the endpoint cannot be used to browse finished
        // work. And everything it can reveal about an open one — that it exists, and who holds it
        // — is already visible to every holder of `design_tickets.accept` through the pool.
        $this->refuseUnlessVisibleTicket($request, $ticket, onlyWhenClosed: true);

        /** @var User $designer */
        $designer = $request->user();

        $accepted = $this->tickets->accept($ticket, $designer);

        return $this->success(
            new DesignTicketResource($this->loadForDisplay($request, $accepted)),
            'تم قبول الطلب',
        );
    }

    /**
     * Cancel a design ticket
     *
     * For a ticket that should not have been raised, or that nobody wants any more. The reason is
     * required: «الزبون غيّر رأيه» and «فُتحت بالخطأ» are the same status and entirely different
     * facts, and a designer whose job disappeared overnight is owed the difference.
     *
     * **Not a way to reject a design** — that is «طلب تعديل», which keeps the ticket alive.
     * Versions already uploaded stay exactly where they are: the work was done.
     */
    public function cancel(CancelDesignTicketRequest $request, DesignTicket $ticket): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $cancelled = $this->tickets->cancel(
            $ticket,
            (string) $request->validated('reason'),
            $request->user(),
        );

        return $this->success(
            new DesignTicketResource($this->loadForDisplay($request, $cancelled)),
            'تم إلغاء التذكرة',
        );
    }

    /**
     * Attach a reference file
     *
     * Send as `multipart/form-data`. Accepts pdf, jpeg, png or webp — the logo, a photo of a
     * similar bag, whatever makes the request answerable.
     *
     * Allowed for as long as the ticket is open, not only at creation: «هذا مثال لما أقصده»
     * arrives in the middle of a revision round at least as often as it arrives with the original
     * request.
     */
    public function storeAttachment(
        StoreDesignTicketAttachmentRequest $request,
        DesignTicket $ticket,
    ): JsonResponse {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $file = $this->tickets->attach(
            $ticket,
            $request->file('file'),
            $request->user(),
            $request->string('note')->toString() ?: null,
        );

        return $this->created(
            new DesignTicketFileResource($file->load('uploader')),
            'تم رفع المرفق',
        );
    }

    /**
     * Remove a reference file
     *
     * Hides it from the ticket; the object stays, because a designer may already be working from
     * it and a tidy-up that made it unopenable would break work in progress.
     *
     * **Only a brief can be removed.** A version is a statement in a conversation — deleting one
     * would leave a change request referring to something nobody can see — so naming one here is a
     * 404 rather than a refusal.
     */
    public function destroyAttachment(
        Request $request,
        DesignTicket $ticket,
        DesignTicketFile $attachment,
    ): JsonResponse {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        if ($attachment->kind !== DesignTicketFileKind::Brief) {
            throw new NotFoundHttpException;
        }

        $this->tickets->deleteAttachment($attachment);

        return $this->successMessage('تم حذف المرفق');
    }

    /**
     * Upload a design
     *
     * The designer's work, as `multipart/form-data`. The ticket moves to «بانتظار المراجعة» and
     * the employee who raised it is told.
     *
     * **The same endpoint sends the first version and every revision.** A revision is a row, not a
     * new ticket — «طلب التعديل يعيد التذكرة للمصمم دون إنشاء تذكرة جديدة» — and the version
     * number is allocated by the server, never sent.
     *
     * **Nothing is ever replaced.** There is no endpoint that swaps a version's bytes; every
     * earlier one stays readable for good.
     */
    public function submitVersion(SubmitDesignVersionRequest $request, DesignTicket $ticket): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        /** @var User $designer */
        $designer = $request->user();

        $version = $this->tickets->submit(
            $ticket,
            $request->file('file'),
            $designer,
            $request->string('note')->toString() ?: null,
        );

        return $this->created(
            new DesignTicketFileResource($version->load('uploader')),
            'تم إرسال التصميم للمراجعة',
        );
    }

    /**
     * Review a design
     *
     * `verdict: approved` closes the ticket and puts the artwork on the customer's account, where
     * every future order can pick it up. `verdict: changes_requested` sends it back with `note`
     * saying what to change — and the note is required, because a change request with no words
     * turns the history into a count.
     *
     * **A version is judged once**, and **the reviewer may not be the person who uploaded it** —
     * the second rule holds even for an administrator, because a permission cannot express it. The
     * same control `orders.deposit.confirm` puts on the person who claimed a payment.
     */
    public function reviewVersion(
        ReviewDesignVersionRequest $request,
        DesignTicket $ticket,
        DesignTicketFile $version,
    ): JsonResponse {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        // A brief is not a version and has nothing to review. A 404 rather than a 422: the id
        // names no reviewable thing, which is a question about the URL, not the body.
        if ($version->kind !== DesignTicketFileKind::Submission) {
            throw new NotFoundHttpException;
        }

        $reviewed = $this->tickets->review(
            $ticket,
            $version,
            $request->verdict(),
            $request->string('note')->toString() ?: null,
            $request->user(),
        );

        return $this->success(
            new DesignTicketFileResource($reviewed->load(['uploader', 'reviewer'])),
            $reviewed->status?->isReviewed() === true && $request->verdict()->requiresNote()
                ? 'تم إرسال طلب التعديل'
                : 'تم اعتماد التصميم',
        );
    }

    /**
     * A ticket's history
     *
     * Everything that happened, from the request to the approval — who raised it and when, who
     * accepted, every message, every file, every version, every change request, who approved, and
     * the moment it closed. Kept in full after the ticket is closed, which is what «الاحتفاظ بسجل
     * كامل للتذكرة حتى بعد إغلاقها» asks for.
     */
    public function logs(
        ActivityLogFilterRequest $request,
        DesignTicket $ticket,
        AuditService $audit,
    ): JsonResponse {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        return $this->auditTrailResponse($request, $ticket, $audit);
    }

    /**
     * Everything the detail payload reads, in one round trip.
     *
     * `Model::shouldBeStrict()` turns a forgotten eager load into a 500 outside production rather
     * than an N+1 nobody notices, so this list and `DesignTicketResource` are kept in step on
     * purpose.
     */
    /**
     * يختم على كلِّ تذكرةٍ كم بقي من ردودها غيرَ مقروءٍ لهذا القارئ — ما ترسمه الشارة.
     *
     * **استعلامٌ واحد للصفحة كلّها، لا واحدٌ لكلِّ صفّ.** وهو سببُ وجود
     * {@see NotificationService::unreadForSubjects()} بصيغة الجمع أصلاً: صفحةٌ من خمس عشرة تذكرة
     * تعني خمسة عشر استعلاماً لو سُئل عن كلٍّ على حدة، وذلك N+1 وهو عيبٌ لا ذوق (RULES §3).
     *
     * **ويُكتب على النموذج لا على المورد**، لأن `DesignTicketResource` لا يجوز أن يستعلم، ولأن
     * علاقةً من `DesignTicket` إلى `Notification` كانت ستقلب اتّجاه التبعيّة: سياقُ الإشعارات
     * يقرأ غيرَه ولا يقرؤه أحد. فالطبقةُ التطبيقيّة هي التي تعرف الاثنين وتجمع بينهما.
     *
     * والصفرُ يُكتب صراحةً حين لا شيء: `whenHas` في المورد تحذف المفتاح الغائب، ومفتاحٌ غائب
     * يترك التطبيق يختار بين الفراغ والصفر، وهما شيئان مختلفان.
     *
     * @param  Collection<int, DesignTicket>  $tickets
     */
    private function stampUnreadComments(Request $request, Collection $tickets): void
    {
        if ($tickets->isEmpty()) {
            return;
        }

        $counts = $this->notifications->unreadForSubjects(
            AuditSubject::DesignTicket->value,
            $tickets->map(fn (DesignTicket $ticket): int => (int) $ticket->getKey())->all(),
            (int) $request->user()?->getKey(),
            NotificationType::DesignTicketComment,
        );

        foreach ($tickets as $ticket) {
            $ticket->setAttribute('unread_comments_count', $counts[(int) $ticket->getKey()] ?? 0);
        }
    }

    private function loadForDisplay(Request $request, DesignTicket $ticket): DesignTicket
    {
        $this->stampUnreadComments($request, new Collection([$ticket]));

        return $ticket->load([
            'customer:id,code',
            'requester', 'designer', 'acceptedBy', 'approvedBy', 'approvedDesign', 'order',
            'latestVersion',
            'attachments.uploader',
            'versions.uploader', 'versions.reviewer',
        ])->loadCount('versions');
    }

    /**
     * The filters, with the two things only this layer knows folded in.
     *
     * `designer=me` needs the signed-in user, and whether the reader sees everything needs their
     * grants. Neither belongs in {@see DesignTicketFilters}, which is handed around the domain
     * where there is no request to ask.
     */
    private function filtersFrom(Request $request): DesignTicketFilters
    {
        $query = $request->only([
            'status', 'designer', 'requested_by', 'customer_id', 'order_id', 'search',
        ]);

        if (($query['designer'] ?? null) === 'me') {
            $query['designer'] = $request->user()?->getKey();
        }

        return DesignTicketFilters::fromArray(
            $query,
            // Null means "no narrowing" — see the DTO. A reader with `view_all` passes null and
            // sees every ticket; everybody else is narrowed to their own id.
            visibleToUserId: $request->user()?->can(PermissionName::ViewAllDesignTickets->value) === true
                ? null
                : $request->user()?->getKey(),
        );
    }
}
