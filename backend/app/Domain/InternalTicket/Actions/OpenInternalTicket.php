<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\DTOs\InternalMessageData;
use App\Domain\InternalTicket\DTOs\InternalTicketData;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Models\InternalTicket;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

/**
 * موظفٌ يفتح تذكرةً إلى زميل.
 *
 * **التذكرةُ وأولى رسائلها معاملةٌ واحدة**، كما في الدعم: تذكرةٌ بلا رسالة عنوانٌ لا يُجاب عنه.
 * و«التفاصيل» هي تلك الرسالة، ومعها صورُ النموذج — حتى أربع، كبريمولا.
 *
 * **تولد «قيد المعالجة»** لا «جديدة»، وبالأولوية «متوسطة» إن لم تُختر.
 *
 * مَن تُوجَّه إليه — موظفٌ نشطٌ غير الفاتح — يحرسه الطلب، والجدولُ يرفض الشخصَ ونفسه
 * (`internal_tickets_two_parties`). والعميلُ والطلبيةُ أرقامٌ تحقّق الطلبُ من وجودها: الربطُ معلومةٌ
 * على التذكرة لا ملكيةٌ تُحرس.
 */
final class OpenInternalTicket
{
    public function __construct(
        private readonly AllocateInternalTicketIdentifier $allocate,
        private readonly PostInternalMessage $postMessage,
    ) {}

    /**
     * @param  list<UploadedFile>  $images
     */
    public function __invoke(User $opener, InternalTicketData $data, array $images = []): InternalTicket
    {
        return DB::transaction(function () use ($opener, $data, $images): InternalTicket {
            $identifier = ($this->allocate)();

            $ticket = new InternalTicket([
                'title' => $data->title,
                'priority' => $data->priority,
                'category_id' => $data->categoryId,
                'customer_id' => $data->customerId,
                'order_id' => $data->orderId,
            ]);

            // لا شيء من هذا قابلٌ للتعبئة — انظر InternalTicket.
            $ticket->id = $identifier->id;
            $ticket->code = $identifier->code;
            $ticket->status = InternalTicketStatus::InProgress;
            $ticket->opened_by = (int) $opener->getKey();
            $ticket->assignee_id = $data->assigneeId;
            $ticket->last_message_at = now();
            $ticket->save();

            ($this->postMessage)(
                $ticket,
                $opener,
                new InternalMessageData(body: $data->description, files: $images),
                announceAs: InternalTicketChange::Opened,
            );

            return $ticket->refresh();
        });
    }
}
