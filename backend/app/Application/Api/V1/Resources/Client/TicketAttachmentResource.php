<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Application\Api\V1\Resources\SupportTicketMessageResource;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * ملفُّ رسالةٍ في محادثة الدعم، بالشكل نفسه للطرفين.
 *
 * **شكلٌ واحد في مكانٍ واحد**: {@see ClientTicketMessageResource} و{@see SupportTicketMessageResource}
 * يرسلانه كما هو، فلا يفترق ما يراه العميل عمّا يراه المكتب يوم يُضاف حقل. لا شيء فيه يخصّ أحداً:
 * اسمُ الملف كما سمّاه مرسله، ونوعه كما قرأه الخادم من بايتاته.
 *
 * **الأبعاد للصور وحدها**، كي يحجز التطبيق مكان الصورة بنسبتها قبل أن تصل — فلا تقفز المحادثة
 * تحت إصبع من يقرأ. و`url` يُبنى عند كل طلب ولا يُخزَّن: القرص خاص، والرابط موقَّعٌ ينتهي.
 *
 * @mixin TicketMessage
 */
class TicketAttachmentResource extends JsonResource
{
    /**
     * `null` لرسالةٍ بلا ملف — ليقول الحقل «لا ملف» بدل أن يغيب.
     *
     * @return array<string, mixed>|null
     */
    public static function for(TicketMessage $message): ?array
    {
        return $message->hasAttachment() ? (new self($message))->resolve() : null;
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'kind' => $this->attachment_kind?->value,
            'kind_label' => $this->attachment_kind?->label(),
            'name' => $this->attachment_filename,
            'mime_type' => $this->attachment_mime_type,
            'size_bytes' => $this->attachment_size_bytes,
            'width_px' => $this->attachment_width_px,
            'height_px' => $this->attachment_height_px,
            'url' => $this->attachmentUrl(),
        ];
    }
}
