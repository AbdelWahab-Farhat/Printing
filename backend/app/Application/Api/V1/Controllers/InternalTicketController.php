<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\InternalTicket\EditInternalMessageRequest;
use App\Application\Api\V1\Requests\InternalTicket\ListInternalTicketsRequest;
use App\Application\Api\V1\Requests\InternalTicket\OpenInternalTicketRequest;
use App\Application\Api\V1\Requests\InternalTicket\PostInternalMessageRequest;
use App\Application\Api\V1\Requests\InternalTicket\TransferInternalTicketRequest;
use App\Application\Api\V1\Resources\InternalTicket\InternalTicketColleagueResource;
use App\Application\Api\V1\Resources\InternalTicket\InternalTicketMessageResource;
use App\Application\Api\V1\Resources\InternalTicket\InternalTicketResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\DTOs\InternalMessageData;
use App\Domain\InternalTicket\DTOs\InternalTicketData;
use App\Domain\InternalTicket\InternalTicketService;
use App\Domain\InternalTicket\Models\InternalTicketCategory;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;

/**
 * Internal tickets
 *
 * تذاكرُ الموظفين بينهم، كما في بريمولا — Docs/internal-tickets/INTERNAL-TICKETS-DESIGN.md.
 *
 * **لا صلاحية على أيّ مسارٍ هنا**: كلُّ موظفٍ يفتح تذكرةً ويكتب فيما هو طرفٌ فيه. الحكمُ على الصف —
 * تذكرةٌ لا يراها القارئ ٤٠٤، وما يراها ولا يملك الكتابة فيها ٤٠٣ — في السياق لا هنا.
 */
class InternalTicketController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    /**
     * ما يرسمه جوابُ كل كتابةٍ على المحادثة: الخيطُ بكتّابه ومرفقاته واقتباساته، ومَن حوله.
     *
     * **كاملٌ وليس زينة**، كخيط الدعم: الوضعُ الصارم يرمي على كل علاقةٍ نُسيت، والموردُ يقرأها كلها.
     */
    private const THREAD = [
        'opener',
        'assignee',
        'closer',
        'category',
        'customer',
        'order',
        'latestLiveMessage.author',
        'latestLiveMessage.attachments',
        'messages.author',
        'messages.attachments',
        'messages.replyTo.author',
        'messages.replyTo.attachments',
    ];

    /** ما يرسمه موردُ رسالةٍ واحدة. */
    private const MESSAGE = ['ticket', 'author', 'attachments', 'replyTo.author', 'replyTo.attachments'];

    /** أجراسُ التذكرة التي يطفئها فتحُها. */
    private const BELLS = [
        NotificationType::InternalTicketOpened,
        NotificationType::InternalTicketMessage,
        NotificationType::InternalTicketReminder,
    ];

    public function __construct(private readonly InternalTicketService $tickets) {}

    /**
     * The list
     *
     * تذاكري، الأحدث نشاطاً أولاً. المدير وحده يطلب `scope=all`.
     */
    public function index(ListInternalTicketsRequest $request): JsonResponse
    {
        $reader = $this->reader($request);

        $page = $this->tickets->paginate($reader, $request->filters($reader->isAdmin()), $request->perPage());

        return $this->successWithPagination(InternalTicketResource::collection($page));
    }

    /**
     * The home card
     *
     * حتى عشر تذاكر مفتوحة تنتظر ردّي — آخرُ كلامٍ فيها لزميلي — وأرقامُ ما على مكتبي.
     */
    public function home(Request $request): JsonResponse
    {
        $home = $this->tickets->home($this->reader($request));

        return $this->success([
            'tickets' => InternalTicketResource::collection($home->tickets),
            'awaiting_my_reply' => $home->awaitingMyReply,
            'has_more' => $home->hasMore,
            'total_open' => $home->totalOpen,
            'unread_tickets' => $home->unreadTickets,
        ], 'التذاكر التي تنتظر ردّك');
    }

    /**
     * Colleagues
     *
     * ورقةُ «مع مَن؟»: الموظفون النشطون غيري، مَن بيني وبينه تذاكرُ مفتوحة أولاً.
     */
    public function colleagues(Request $request): JsonResponse
    {
        return $this->success(InternalTicketColleagueResource::collection(
            $this->tickets->colleaguesOf($this->reader($request)),
        ));
    }

    /**
     * Categories
     *
     * «نوع المشكلة»: الأنواعُ النشطة بترتيبها.
     */
    public function categories(): JsonResponse
    {
        return $this->success($this->tickets->activeCategories()->map(fn (InternalTicketCategory $category) => [
            'id' => $category->id,
            'name' => $category->name,
        ])->values());
    }

    /**
     * Open a ticket
     *
     * التذكرةُ وأولى رسائلها — «التفاصيل» وحتى أربع صور. تولد «قيد المعالجة».
     */
    public function store(OpenInternalTicketRequest $request): JsonResponse
    {
        /** @var list<UploadedFile> $images */
        $images = array_values((array) $request->file('images', []));

        $ticket = $this->tickets->open(
            $this->reader($request),
            InternalTicketData::fromArray($request->validated()),
            $images,
        );

        return $this->created(new InternalTicketResource($ticket->load(self::THREAD)), 'تم فتح التذكرة');
    }

    /**
     * One ticket
     *
     * المحادثةُ كاملة. فتحُها يعلّمها مقروءةً لطرفيها — لا للمدير الذي يقرأ ولا طرفَ له — ويطفئ
     * أجراسها عند هذا القارئ.
     */
    public function show(Request $request, int $ticket, NotificationService $notifications): JsonResponse
    {
        $reader = $this->reader($request);
        $found = $this->tickets->findVisible($reader, $ticket, ['messages']);

        // حتى آخر رسالةٍ حُمّلت هنا، لا حتى «الآن».
        $lastLoaded = $found->messages->max('id');
        $this->tickets->markRead($found, $reader, $lastLoaded === null ? null : (int) $lastLoaded);

        // مَن فتح المحادثة قرأ أجراسها، كما في الدعم وتعليقات التصميم.
        foreach (self::BELLS as $type) {
            $notifications->markSubjectAsRead(
                AuditSubject::InternalTicket->value,
                (int) $found->getKey(),
                (int) $reader->getKey(),
                $type,
            );
        }

        return $this->success(new InternalTicketResource($found->refresh()->load(self::THREAD)));
    }

    /**
     * Post a message
     *
     * نصٌّ، أو صورة، أو رسالة صوتية (`file` مع `duration_seconds` و`waveform`)، ويقتبس بـ
     * `reply_to_message_id`. multipart حين يُرفق ملف.
     */
    public function reply(PostInternalMessageRequest $request, int $ticket): JsonResponse
    {
        $reader = $this->reader($request);
        $found = $this->tickets->findVisible($reader, $ticket);

        $file = $request->file('file');

        $this->tickets->post(
            $found,
            $reader,
            InternalMessageData::fromArray($request->validated(), $file instanceof UploadedFile ? $file : null),
        );

        return $this->created(new InternalTicketResource($found->refresh()->load(self::THREAD)), 'تم إرسال الرسالة');
    }

    /**
     * Edit a message
     *
     * نصُّ رسالتي فقط، خلال عشرين دقيقة، والتذكرةُ مفتوحة. تظهر عليها «معدّلة».
     */
    public function editMessage(EditInternalMessageRequest $request, int $ticket, int $message): JsonResponse
    {
        $reader = $this->reader($request);
        $found = $this->tickets->findVisibleMessage($reader, $ticket, $message);

        $edited = $this->tickets->edit($found, $reader, $request->string('body')->toString());

        return $this->success(new InternalTicketMessageResource($this->loadMessage($edited)), 'تم تعديل الرسالة');
    }

    /**
     * Delete a message
     *
     * رسالتي فقط، بشروط التعديل نفسها. تبقى مكانها وتقول «تم حذف هذه الرسالة».
     */
    public function retractMessage(Request $request, int $ticket, int $message): JsonResponse
    {
        $reader = $this->reader($request);
        $found = $this->tickets->findVisibleMessage($reader, $ticket, $message);

        $retracted = $this->tickets->retract($found, $reader);

        return $this->success(new InternalTicketMessageResource($this->loadMessage($retracted)), 'تم حذف الرسالة');
    }

    /**
     * Mark as read
     *
     * لشاشةٍ مفتوحة وصلتها رسالةٌ حيّة: `up_to_message_id` آخرُ ما عُرض. فتحُ التذكرة يعلّمها وحده.
     */
    public function read(Request $request, int $ticket): JsonResponse
    {
        $validated = $request->validate([
            'up_to_message_id' => ['nullable', 'integer', 'min:1'],
        ]);

        $reader = $this->reader($request);
        $found = $this->tickets->findVisible($reader, $ticket);

        $this->tickets->markRead(
            $found,
            $reader,
            isset($validated['up_to_message_id']) ? (int) $validated['up_to_message_id'] : null,
        );

        return $this->successMessage('تم');
    }

    /**
     * Close a ticket
     *
     * نهائيّ، ولطرفيها والمدير. إغلاقُ المغلقة لا يكتب شيئاً ولا يُعدّ خطأ.
     */
    public function close(Request $request, int $ticket): JsonResponse
    {
        $reader = $this->reader($request);

        $closed = $this->tickets->close($this->tickets->findVisible($reader, $ticket), $reader);

        return $this->success(new InternalTicketResource($closed->load(self::THREAD)), 'تم إغلاق التذكرة');
    }

    /**
     * Transfer a ticket
     *
     * صاحبُها (أو المدير) يسلّمها لموظفٍ آخر يحلّ محلّه، والزميلُ الذي وُجّهت إليه يبقى.
     */
    public function transfer(TransferInternalTicketRequest $request, int $ticket): JsonResponse
    {
        $reader = $this->reader($request);
        $found = $this->tickets->findVisible($reader, $ticket);
        $newOwner = User::query()->findOrFail((int) $request->integer('new_owner_id'));

        $transferred = $this->tickets->transfer($found, $reader, $newOwner);

        return $this->success(new InternalTicketResource($transferred->load(self::THREAD)), 'تم تحويل التذكرة');
    }

    /**
     * Ticket history
     *
     * قصةُ التذكرة كاملة: هي، وكل رسالةٍ وتعديلها، وكل ملف. **وتُضيَّق ثانيةً بالرؤية**، كتذاكر
     * التصميم: `logs.view` وحده لا يقرأ محادثةً بين زميلين.
     */
    public function logs(ActivityLogFilterRequest $request, int $ticket, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse(
            $request,
            $this->tickets->findVisible($this->reader($request), $ticket),
            $audit,
        );
    }

    private function reader(Request $request): User
    {
        $user = $request->user();

        assert($user instanceof User);

        return $user;
    }

    private function loadMessage(InternalTicketMessage $message): InternalTicketMessage
    {
        return $message->load(self::MESSAGE);
    }
}
