<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\DesignTicket\Models\DesignTicketMessageAttachment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * صورةٌ أو رسالةٌ صوتية في رسالة تذكرة تصميم — بشكل مرفق التذكرة الداخلية حرفاً بحرف.
 *
 * **`id` هو مفتاحُ الحفظ على الهاتف، لا `url`**: الرابطُ موقّعٌ ويتغيّر مع كل قراءة، والملفُّ خلفه لا
 * يتغيّر أبداً — فينزل الصوت مرّةً واحدة، كما في بريمولا.
 *
 * @mixin DesignTicketMessageAttachment
 */
class DesignTicketMessageAttachmentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'kind' => $this->kind->value,
            'kind_label' => $this->kind->label(),
            'name' => $this->filename,
            'mime_type' => $this->mime_type,
            'size_bytes' => $this->size_bytes,
            'width_px' => $this->width_px,
            'height_px' => $this->height_px,
            'duration_seconds' => $this->duration_seconds,
            'waveform' => $this->waveform,
            'url' => $this->url(),
        ];
    }
}
