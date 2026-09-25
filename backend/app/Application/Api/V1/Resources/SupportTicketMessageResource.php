<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Application\Api\V1\Resources\Client\ClientTicketMessageResource;
use App\Application\Api\V1\Resources\Client\TicketAttachmentResource;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * رسالةٌ في تذكرة، كما يقرؤها المكتب.
 *
 * **موردٌ مستقل لأن للرسالة الآن طريقين**: داخل الخيط في {@see SupportTicketResource}، ووحدها في
 * الحدث الحيّ الذي يحمل الرسالة الجديدة. نسختان من الشكل كانتا ستفترقان يوم يُضاف حقلٌ إلى
 * إحداهما.
 *
 * نسخةُ العميل {@see ClientTicketMessageResource} ولا تحمل اسمَ أحد.
 *
 * @mixin TicketMessage
 */
class SupportTicketMessageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'from' => $this->isFromCustomer() ? 'customer' : 'staff',
            // مسمّى في هذا الطرف بخلاف طرف العميل: «من ردّ عليه؟» سؤالٌ يحقّ للمحل أن يسأله نفسه.
            'author_name' => $this->isFromCustomer() ? null : $this->author?->name,
            'body' => $this->body,
            'attachment' => TicketAttachmentResource::for($this->resource),
            'client_token' => $this->client_token,
            'sent_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
