<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Concerns\CascadesSoftDeletes;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Comment\Concerns\HasComments;
use App\Domain\Comment\Contracts\Commentable;
use App\Domain\Comment\Models\Comment;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\DesignTicket\Actions\AllocateDesignTicketIdentifier;
use App\Domain\DesignTicket\Actions\AssignDesignTicket;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Queries\DesignTicketListQuery;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Models\Order;
use Database\Factories\DesignTicketFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One request for artwork — «صمّم لي كيس شحن بشعاري» — from the asking to the approval.
 *
 * `new → in_progress → under_review → completed`, with «تعديل مطلوب» looping back as many times
 * as it takes. Every one of those moves is written by an action rather than chosen from a list;
 * see {@see DesignTicketStatus}.
 *
 * **Eight columns are missing from the fillable list, and the omissions are the design.** `code`
 * is identity, allocated once. `status` moves only through the actions that earn it.
 * `customer_id` and `customer_name` are set together at creation and never drift apart.
 * `assigned_designer_id` has its own action and its own permission, because whoever routes work
 * is not whoever does it — see {@see AssignDesignTicket}. `accepted_by_user_id`,
 * `approved_by_user_id` and `approved_customer_design_id` are records of things that happened,
 * and a request body that could set them could claim somebody else took the job.
 *
 * **Comments come from {@see HasComments} and the history from {@see Auditable}.** Between them
 * they are the brief's entire «سجل التذكرة» section — who created it, who accepted, the messages,
 * the files, the versions, the change requests, who approved, and when it closed — for two lines.
 */
#[UseFactory(DesignTicketFactory::class)]
#[Fillable(['order_id', 'title', 'description', 'instructions'])]
class DesignTicket extends Model implements Commentable, HasAuditTrail
{
    /** @use HasFactory<DesignTicketFactory> */
    use Auditable, CascadesSoftDeletes, HasComments, HasFactory, SoftDeletes;

    /**
     * The code is allocated here rather than in the action that creates one, for the reason
     * shortages and orders both settled on: `code` is NOT NULL, more than one path creates a row
     * — the action and the factory — and an allocation living in only one of them is a crash
     * waiting for the next caller.
     */
    protected static function booted(): void
    {
        static::creating(function (self $ticket): void {
            if ($ticket->code === null) {
                $identifier = app(AllocateDesignTicketIdentifier::class)();

                $ticket->id = $identifier->id;
                $ticket->code = $identifier->code;
            }
        });
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => DesignTicketStatus::class,
            'accepted_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    // ───────────────────────────── questions the screens ask ─────────────────────────────

    /** Whether anything at all may still be done to this ticket. */
    public function isOpen(): bool
    {
        return $this->status->isOpen();
    }

    /**
     * هل بقي ما يُقال عليها — {@see Commentable}.
     *
     * **الثلثُ الثالث من جملةٍ كتبتها هذه الشيفرة أصلاً.** `DesignTicketStatus::isClosed()` تقول
     * عن «مكتمل» و«ملغى» إنه «لا شيء بعدهما يُرسم ولا يُراجع ولا يُقال»، وكان الثلثان الأولان
     * مطبَّقَين من اليوم الأول والثالث لا. والتذكرة التي اعتُمدت هي سجلُّ ما اتُّفق عليه، والسجلُّ
     * الذي يستطيع أحدٌ أن يضيف إليه — أو أن يعيد كتابته صامتاً — ليس سجلّاً.
     *
     * و*حالُ* التذكرة هي التي تُغلقها، لا صلاحية أبداً: والمشرف يُرفض هو أيضاً.
     */
    public function acceptsComments(): bool
    {
        return $this->isOpen();
    }

    /**
     * أيَّ نهايتيها بلغت، لأنهما تعنيان شيئين مختلفين لمن يمسك الهاتف — وهو التمييز نفسه الذي
     * يصنعه {@see DesignTicketIsClosed}.
     */
    public function commentsClosedNote(): ?string
    {
        return match ($this->status) {
            DesignTicketStatus::Completed => 'اعتُمد التصميم وأُغلقت المحادثة',
            DesignTicketStatus::Cancelled => 'أُلغيت التذكرة وأُغلقت المحادثة',
            default => null,
        };
    }

    /** Whether somebody has taken it. The fact, not the intention — see the column's comment. */
    public function isAccepted(): bool
    {
        return $this->accepted_at !== null;
    }

    /**
     * Whether this reader is the designer who may work on this ticket.
     *
     * **Before acceptance the pool is open to whoever it was addressed to**, which is everybody
     * when it was addressed to nobody. After acceptance it is the one person who took it, and
     * addressing the ticket to a second designer does not change that — naming somebody is not
     * taking the job off the person doing it.
     *
     * **Returning it to the shared pool does**, and it is the only thing that does: `AssignDesignTicket`
     * clears the claim along with the address, so the ticket is unaccepted and open to whoever
     * picks it up next. That is what makes a designer who goes home sick recoverable.
     *
     * Lives on the model rather than in the controller because the same question is asked twice:
     * once to refuse a request, once to tell the app whether to draw the button. Two copies of an
     * authorization rule is one copy too many — the reasoning `Comment::isChangeableBy()` sets
     * out.
     */
    public function isWorkableBy(?User $user): bool
    {
        if ($user === null) {
            return false;
        }

        if ($this->isAccepted()) {
            return (int) $this->accepted_by_user_id === (int) $user->getKey();
        }

        return $this->assigned_designer_id === null
            || (int) $this->assigned_designer_id === (int) $user->getKey();
    }

    /**
     * Whether this reader may be shown this ticket at all.
     *
     * **The narrowing is in {@see DesignTicketListQuery} too, and
     * this is not a duplicate of it.** The query decides what a *page* contains, in SQL, because a
     * page that fetched rows and then dropped them would paginate short. This decides what a
     * *single* binding resolves to, so a colleague's ticket id is a 404 rather than a 403 — which
     * is the honest answer: a reader without `view_all` has no business learning that the ticket
     * exists.
     *
     * Everyone involved may read it: whoever asked, whoever it was addressed to, whoever took it.
     * Plus the unclaimed pool, which is what a designer scrolls to find work. `view_all` skips all
     * of this and is checked by the caller.
     */
    public function isVisibleTo(?User $user): bool
    {
        if ($user === null) {
            return false;
        }

        $id = (int) $user->getKey();

        if ((int) $this->requested_by_user_id === $id
            || (int) $this->assigned_designer_id === $id
            || (int) $this->accepted_by_user_id === $id) {
            return true;
        }

        // The unclaimed pool: addressed to nobody and not yet taken. What a designer is shown so
        // that work without a name on it can be picked up at all.
        return $this->assigned_designer_id === null && ! $this->isAccepted();
    }

    // ───────────────────────────────── the versions ─────────────────────────────────

    /**
     * Every file on this ticket, briefs and submissions alike, oldest first.
     *
     * By `id` rather than `created_at`: two files uploaded in the same second would otherwise
     * come back in whichever order the database felt like, and the timeline is read as a
     * sequence. The same reason `HasComments` gives for ordering by id.
     *
     * @return HasMany<DesignTicketFile, $this>
     */
    public function files(): HasMany
    {
        return $this->hasMany(DesignTicketFile::class)->orderBy('id');
    }

    /**
     * What the employee sent with the request.
     *
     * @return HasMany<DesignTicketFile, $this>
     */
    public function attachments(): HasMany
    {
        return $this->files()->where('kind', DesignTicketFileKind::Brief);
    }

    /**
     * What the designer has drawn, in version order.
     *
     * @return HasMany<DesignTicketFile, $this>
     */
    public function versions(): HasMany
    {
        return $this->files()->where('kind', DesignTicketFileKind::Submission)->orderBy('version');
    }

    /**
     * The newest version, as one row rather than a list.
     *
     * **For the list screen, which draws it as a thumbnail on the card.** A `HasMany` cannot be
     * eager-loaded «one per parent» — twenty tickets would fetch every version of all twenty —
     * and `latestOfMany` is the relation that compiles to exactly that per-parent subquery.
     *
     * Ordered by `version`, not by `id`: the number is allocated by the action and is the only
     * thing that says which came last.
     *
     * @return HasOne<DesignTicketFile, $this>
     */
    public function latestVersion(): HasOne
    {
        return $this->hasOne(DesignTicketFile::class)
            ->where('kind', DesignTicketFileKind::Submission)
            ->latestOfMany('version');
    }

    /**
     * The version currently sitting with the reviewer, if any.
     *
     * At most one can exist: a submission moves the ticket to «بانتظار المراجعة», and no second
     * one may be uploaded from there.
     */
    public function pendingVersion(): ?DesignTicketFile
    {
        return $this->versions()->where('status', DesignSubmissionStatus::Proposed)->first();
    }

    // ───────────────────────────────── relations ─────────────────────────────────

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * The order this came off, **archived ones included**.
     *
     * `withTrashed()` for the reason `Shortage::order()` carries it: the ticket belongs to the
     * order it belongs to whether or not somebody has since archived it, and the scoped relation
     * would answer null for exactly the rows a reader needs told about. Unlike a shortage, no
     * visibility rule hangs off this — a ticket is not readable through its order — so there is
     * no guard to keep in step with it.
     *
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class)->withTrashed();
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by_user_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function designer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_designer_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function acceptedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'accepted_by_user_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by_user_id');
    }

    /**
     * What the approval put on the customer's account.
     *
     * @return BelongsTo<CustomerDesign, $this>
     */
    public function approvedDesign(): BelongsTo
    {
        return $this->belongsTo(CustomerDesign::class, 'approved_customer_design_id');
    }

    // ───────────────────────── soft deletes and the audit trail ─────────────────────────

    /**
     * The files and the conversation go with it.
     *
     * The `Shortage` calculation rather than the `Order` one: nothing outside this row reads a
     * ticket's files or its comments, so following the parent costs nothing, and leaving them
     * behind would leave a timeline pointing at a ticket the API says does not exist.
     *
     * **The approved design is deliberately not here.** It belongs to the customer now, and an
     * order may already be printing from it — see the `nullOnDelete` on
     * `customer_designs.design_ticket_id`.
     *
     * @return list<string>
     */
    public function softDeleteCascades(): array
    {
        return ['files', 'comments'];
    }

    /**
     * Its own history, plus the rows it owns.
     *
     * The files and the comments are where the story actually is — «من رفع النسخة الثالثة؟» and
     * «متى طلب التعديل؟» are the questions this endpoint exists to answer, and neither lives on
     * the ticket row. The same reasoning a product's log covers its sizes and prices.
     *
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        return [
            $this->getMorphClass() => [$this->getKey()],
            (new DesignTicketFile)->getMorphClass() => $this->files()->withTrashed()
                ->pluck('id')->all(),
            (new Comment)->getMorphClass() => $this->comments()
                ->withTrashed()->pluck('id')->all(),
        ];
    }
}
