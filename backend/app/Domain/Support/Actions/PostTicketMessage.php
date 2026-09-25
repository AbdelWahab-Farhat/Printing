<?php

declare(strict_types=1);

namespace App\Domain\Support\Actions;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\Support\Enums\TicketChange;
use App\Domain\Support\Enums\TicketStatus;
use App\Domain\Support\Events\TicketChanged;
use App\Domain\Support\Exceptions\TicketIsClosedToStaff;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * Adds one message to a thread, and moves the ticket the way a reply moves it.
 *
 * **The status is a consequence of who spoke, not a field anybody sets.** Staff replying puts a
 * ticket on somebody's desk; a customer replying to something we had closed reopens it, because
 * a closed ticket that a person is still writing into is not closed — it is closed on paper and
 * open in fact, and that gap is where a customer gets ignored.
 *
 * **A customer may write into a closed ticket; staff may not.** The asymmetry is deliberate. For
 * the customer it is the only reasonable reading of «رد» on a thread they can still see, and the
 * reopen is exactly what they meant. For staff it would be re-opening a conversation the shop
 * had decided was over without saying so: if they have something to add, the ticket gets
 * reopened on purpose first.
 *
 * The read cursor moves for the writer in the same transaction — you have read what you just
 * wrote — so a reply never leaves its own author with an unread badge.
 *
 * **ومَن كتب فقد قرأ ما قبل كتابته**: المؤشّر يتقدّم إلى رقم رسالته هو، فتصير رسائل الطرف الآخر
 * قبلها مقروءةً — كما في كل تطبيق محادثة. وردُّ الطلب يحمل الخيط كاملاً، فما وصل بين آخر قراءةٍ
 * والرد يظهر على الشاشة في اللحظة نفسها.
 *
 * **والرسالة كلامٌ أو ملفٌّ أو كلاهما** — انظر {@see StoreTicketAttachment}. و`$clientToken`
 * يجعل الإعادة آمنة: الرمز نفسه في التذكرة نفسها يُرجع الرسالة الأولى، لا يكتب ثانيةً ولا يحفظ
 * ملفاً ثانياً ولا يُعلن شيئاً من جديد.
 */
final class PostTicketMessage
{
    public function __construct(private readonly StoreTicketAttachment $storeAttachment) {}

    public function __invoke(
        SupportTicket $ticket,
        ?string $body,
        ?User $staff = null,
        ?Customer $customer = null,
        ?UploadedFile $file = null,
        ?string $clientToken = null,
    ): TicketMessage {
        if ($staff !== null && $ticket->status === TicketStatus::Closed) {
            throw TicketIsClosedToStaff::make();
        }

        // يُجاب قبل أن يُكتب شيء: الإعادة لا تكلّف شيئاً ولا تغيّر شيئاً.
        if ($clientToken !== null && ($sent = $this->alreadySent($ticket, $clientToken)) !== null) {
            return $sent;
        }

        // الملف قبل المعاملة وخارجها — انظر StoreTicketAttachment.
        $attachment = $file === null ? [] : ($this->storeAttachment)($ticket, $file);

        [$message, $isNew] = $this->write($ticket, $body, $staff, $customer, $attachment, $clientToken);

        // طلبان بالرمز نفسه في اللحظة نفسها: سبق أحدهما، فيُرجَع ما كتبه ويُمحى ملفُّ الآخر.
        if (! $isNew && isset($attachment['attachment_path'])) {
            Storage::disk((string) $attachment['attachment_disk'])->delete((string) $attachment['attachment_path']);
        }

        return $message;
    }

    private function alreadySent(SupportTicket $ticket, string $clientToken): ?TicketMessage
    {
        return TicketMessage::query()
            ->where('support_ticket_id', $ticket->getKey())
            ->where('client_token', $clientToken)
            ->first();
    }

    /**
     * **صفُّ التذكرة مقفلٌ طوال الكتابة**، فتُكتب رسائل التذكرة الواحدة واحدةً بعد واحدة. بذلك
     * يصير «هل وصلت رسالةٌ بهذا الرمز؟» ثم «اكتبها» خطوةً واحدة لا يدخل بينهما طلبٌ آخر بالرمز
     * نفسه — بلا `catch` على الفهرس الفريد، الذي يبقى حارساً أخيراً لا طريقاً عادياً.
     *
     * @param  array<string, mixed>  $attachment
     * @return array{0: TicketMessage, 1: bool} الرسالة، وهل كُتبت الآن
     */
    private function write(
        SupportTicket $ticket,
        ?string $body,
        ?User $staff,
        ?Customer $customer,
        array $attachment,
        ?string $clientToken,
    ): array {
        return DB::transaction(function () use ($ticket, $body, $staff, $customer, $attachment, $clientToken): array {
            SupportTicket::query()->whereKey($ticket->getKey())->lockForUpdate()->first();

            if ($clientToken !== null && ($sent = $this->alreadySent($ticket, $clientToken)) !== null) {
                return [$sent, false];
            }

            $message = new TicketMessage(['body' => $body === '' ? null : $body]);

            $message->support_ticket_id = $ticket->getKey();
            // Stamped here and nowhere else. Exactly one, which the table's CHECK also demands.
            $message->user_id = $staff?->getKey();
            $message->customer_id = $customer?->getKey();
            // مختومٌ هنا لا معبّأ: ما قرأه StoreTicketAttachment من الملف نفسه.
            $message->forceFill([...$attachment, 'client_token' => $clientToken]);
            $message->save();

            $ticket->last_message_at = $message->created_at;

            if ($staff !== null) {
                // The shop has answered, so it is on a desk now.
                $ticket->status = TicketStatus::InProgress;
                $ticket->staff_read_at = $message->created_at;
                $ticket->staff_read_message_id = (int) $message->getKey();
            } else {
                // A customer writing into a closed thread reopens it — see the class comment.
                if ($ticket->status === TicketStatus::Closed) {
                    $ticket->status = TicketStatus::Open;
                    $ticket->closed_at = null;
                    $ticket->closed_by = null;
                }

                $ticket->customer_read_at = $message->created_at;
                $ticket->customer_read_message_id = (int) $message->getKey();
            }

            $ticket->save();

            // يُعلَن داخل المعاملة ويُرسَل بعد التزامها (`ShouldDispatchAfterCommit`): رسالةٌ رآها
            // الطرفُ الآخر ثم تراجعت معاملتها لا سبيل إلى سحبها من شاشته. ومنها أولى رسائل
            // التذكرة، فـOpenTicket لا يُعلن شيئاً بنفسه.
            TicketChanged::dispatch((int) $ticket->getKey(), TicketChange::MessagePosted, (int) $message->getKey());

            return [$message, true];
        });
    }
}
