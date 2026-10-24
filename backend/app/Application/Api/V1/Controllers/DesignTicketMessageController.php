<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\NarrowsDesignTickets;
use App\Application\Api\V1\Requests\DesignTicket\EditDesignTicketMessageRequest;
use App\Application\Api\V1\Requests\DesignTicket\PostDesignTicketMessageRequest;
use App\Application\Api\V1\Resources\DesignTicketMessageResource;
use App\Application\Api\V1\Resources\DesignTicketThreadResource;
use App\Application\Controller;
use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\DesignTicket\DesignTicketService;
use App\Domain\DesignTicket\DTOs\DesignTicketMessageData;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Design ticket conversation
 *
 * «الرد داخل التذكرة» — المحادثة بين الموظف الذي طلب والمصمّم الذي يعمل، **على محرّك التذاكر
 * الداخلية**: نصٌّ وصورٌ ورسائل صوتية، والاقتباس، والتعديلُ والسحبُ خلال عشرين دقيقة، و✓✓ —
 * Docs/design-tickets/DESIGN-TICKET-CHAT.md.
 *
 * **كلُّ تابعٍ يضيّق إلى التذكرة أولاً**، كـ{@see DesignTicketCommentController}: `can:design_tickets.view`
 * على المسار إذنٌ لا نطاق، وتذكرةُ زميلٍ لا يراها القارئ ٤٠٤. ورسالةُ تذكرةٍ أخرى ٤٠٤ عبر هذه —
 * `scopeBindings` على المسار يحلّ `{message}` من رسائل `{ticket}` وحدها.
 */
class DesignTicketMessageController extends Controller
{
    use NarrowsDesignTickets, ResponseTrait;

    /** ما ترسمه المحادثة: الطرفان، والرسائلُ بكتّابها ومرفقاتها واقتباساتها. */
    private const THREAD = [
        'requester',
        'designer',
        'acceptedBy',
        'messages.author',
        'messages.attachments',
        'messages.replyTo.author',
        'messages.replyTo.attachments',
    ];

    /** ما يرسمه موردُ رسالةٍ واحدة. */
    private const MESSAGE = ['ticket', 'author', 'attachments', 'replyTo.author', 'replyTo.attachments'];

    public function __construct(private readonly DesignTicketService $tickets) {}

    /**
     * The conversation
     *
     * المحادثةُ كاملة، أقدمُها أولاً. **فتحُها يعلّمها مقروءة** لطرفيها — لا لمن يقرأ ولا طرفَ له —
     * ويطفئ جرسَها وشارتَها عند هذا القارئ.
     */
    public function index(Request $request, DesignTicket $ticket, NotificationService $notifications): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $reader = $this->reader($request);
        $ticket->load('messages');

        // حتى آخر رسالةٍ حُمّلت هنا، لا حتى «الآن».
        $lastLoaded = $ticket->messages->max('id');
        $this->tickets->markRead($ticket, $reader, $lastLoaded === null ? null : (int) $lastLoaded);
        $this->clearTheBell($notifications, $ticket, $reader);

        return $this->success(new DesignTicketThreadResource($ticket->refresh()->load(self::THREAD)));
    }

    /**
     * Post a message
     *
     * نصٌّ، أو صور (`files[]` حتى عشر، رسالةٌ واحدة بتعليقها)، أو رسالة صوتية (`file` مع
     * `duration_seconds` و`waveform`)، ويقتبس بـ`reply_to_message_id`. multipart حين يُرفق ملف.
     * يُجاب بالمحادثة كلّها.
     */
    public function store(PostDesignTicketMessageRequest $request, DesignTicket $ticket): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $this->tickets->post(
            $ticket,
            $this->reader($request),
            DesignTicketMessageData::fromArray($request->validated(), $request->attachedFiles()),
        );

        return $this->created(
            new DesignTicketThreadResource($ticket->refresh()->load(self::THREAD)),
            'تم إرسال الرسالة',
        );
    }

    /**
     * Edit a message
     *
     * نصُّ رسالتي فقط، خلال عشرين دقيقة، والتذكرةُ مفتوحة. تظهر عليها «معدّلة».
     */
    public function update(
        EditDesignTicketMessageRequest $request,
        DesignTicket $ticket,
        DesignTicketMessage $message,
    ): JsonResponse {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $edited = $this->tickets->editMessage($message, $this->reader($request), $request->string('body')->toString());

        return $this->success(new DesignTicketMessageResource($edited->load(self::MESSAGE)), 'تم تعديل الرسالة');
    }

    /**
     * Delete a message
     *
     * رسالتي فقط، بشروط التعديل نفسها. تبقى مكانها وتقول «تم حذف هذه الرسالة».
     */
    public function destroy(Request $request, DesignTicket $ticket, DesignTicketMessage $message): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $retracted = $this->tickets->retractMessage($message, $this->reader($request));

        return $this->success(new DesignTicketMessageResource($retracted->load(self::MESSAGE)), 'تم حذف الرسالة');
    }

    /**
     * Mark as read
     *
     * لشاشةٍ مفتوحة وصلتها رسالةٌ حيّة: `up_to_message_id` آخرُ ما عُرض. ويطفئ الجرسَ كما يفعل فتحُها،
     * ويُرجع العدَّ الكلّيّ للجرس فيصحّح التطبيق الشارتين بذهابٍ واحد.
     */
    public function read(Request $request, DesignTicket $ticket, NotificationService $notifications): JsonResponse
    {
        $validated = $request->validate([
            'up_to_message_id' => ['nullable', 'integer', 'min:1'],
        ]);

        $this->refuseUnlessVisibleTicket($request, $ticket);

        $reader = $this->reader($request);

        $this->tickets->markRead(
            $ticket,
            $reader,
            isset($validated['up_to_message_id']) ? (int) $validated['up_to_message_id'] : null,
        );
        $this->clearTheBell($notifications, $ticket, $reader);

        return $this->success([
            'unread_comments_count' => 0,
            'unread_total' => $notifications->unreadCountFor((int) $reader->getKey()),
        ]);
    }

    /**
     * مَن قرأ المحادثة في مكانها قرأ أجراسها — الشارةُ وصفوفُ الجرس شيءٌ واحد، كما في
     * {@see DesignTicketCommentController::markThreadAsRead()}.
     */
    private function clearTheBell(NotificationService $notifications, DesignTicket $ticket, User $reader): void
    {
        $notifications->markSubjectAsRead(
            AuditSubject::DesignTicket->value,
            (int) $ticket->getKey(),
            (int) $reader->getKey(),
            NotificationType::DesignTicketComment,
        );
    }

    private function reader(Request $request): User
    {
        $user = $request->user();

        assert($user instanceof User);

        return $user;
    }
}
