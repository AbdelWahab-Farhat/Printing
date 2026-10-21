<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\InternalTicket\Enums\InternalAttachmentKind;
use Database\Factories\InternalTicketAttachmentFactory;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

/**
 * صورةٌ أو رسالةٌ صوتية في رسالةٍ داخلية.
 *
 * **لا شيء فيه قابلٌ للتعبئة.** كلُّ عمودٍ يختمه `StoreInternalAttachment` مما قرأه من الملف
 * نفسه: نوعٌ أو مسارٌ يختاره المرسل هو بالضبط ما يُمنع. والمدّة والموجة من الهاتف، للعرض وحده.
 *
 * **سحبُ الرسالة لا يمسح ملفّها.** تختفي من العرض وتبقى على القرص للتدقيق، كبريمولا.
 */
#[UseFactory(InternalTicketAttachmentFactory::class)]
class InternalTicketAttachment extends Model
{
    /** @use HasFactory<InternalTicketAttachmentFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'kind' => InternalAttachmentKind::class,
            'size_bytes' => 'integer',
            'width_px' => 'integer',
            'height_px' => 'integer',
            'duration_seconds' => 'integer',
            'waveform' => 'array',
        ];
    }

    /**
     * @return BelongsTo<InternalTicketMessage, $this>
     */
    public function message(): BelongsTo
    {
        return $this->belongsTo(InternalTicketMessage::class, 'message_id');
    }

    /**
     * رابطُ الملف، يُبنى عند كل طلب ولا يُخزَّن — القرص خاص، والرابط موقّعٌ ينتهي حيث يقدر القرص.
     * ولهذا يحفظ التطبيق الصوت بمفتاح المرفق لا بالرابط، كما في بريمولا.
     */
    public function url(): string
    {
        $disk = Storage::disk($this->disk);

        return $disk->providesTemporaryUrls()
            ? $disk->temporaryUrl($this->path, now()->addMinutes((int) config('media.temporary_url_minutes')))
            : $disk->url($this->path);
    }
}
