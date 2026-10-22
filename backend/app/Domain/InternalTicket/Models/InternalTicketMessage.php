<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalAttachmentKind;
use Carbon\CarbonInterface;
use Database\Factories\InternalTicketMessageFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * كلامٌ قاله أحدُ الطرفين في تذكرةٍ داخلية: نصٌّ، أو صورة، أو صوت، أو نصٌّ مع مرفقاته.
 *
 * **`body` وحده قابلٌ للتعبئة**، كرسالة الدعم وللسبب نفسه: الكاتبُ يُختم من الموظف المصادَق ولا
 * طريق إلى تغييره، فلا يوقّع جسمُ طلبٍ باسم أحدٍ جملةً لم يقلها.
 *
 * **`original_body` مخفيٌّ** عن كل `toArray()` وكل مورد: النصُّ الأول يُحفظ للتدقيق عند الخلاف،
 * ولا يقرؤه أحدٌ عبر الـ API — قرار بريمولا ٢٠٢٦-٠٩-٢٤ كما هو.
 */
#[UseFactory(InternalTicketMessageFactory::class)]
#[Fillable(['body'])]
#[Hidden(['original_body'])]
class InternalTicketMessage extends Model
{
    /** @use HasFactory<InternalTicketMessageFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * مهلةُ التعديل والحذف من لحظة الإرسال، كبريمولا. مصدرٌ واحد: الرفضُ وجملتُه وأعلامُ المورد.
     */
    public const MUTATION_WINDOW_MINUTES = 20;

    /** ما تقوله الرسالة المسحوبة مكانها، كواتساب. */
    public const RETRACTED_PLACEHOLDER = 'تم حذف هذه الرسالة';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'edited_at' => 'datetime',
            'retracted_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<InternalTicket, $this>
     */
    public function ticket(): BelongsTo
    {
        return $this->belongsTo(InternalTicket::class, 'internal_ticket_id');
    }

    /**
     * بالمؤرشَفين أيضاً، كطرفَي التذكرة: ما قاله موظفٌ غادر يبقى باسمه.
     *
     * @return BelongsTo<User, $this>
     */
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id')->withTrashed();
    }

    /**
     * الرسالة التي يقتبسها هذا الردّ.
     *
     * @return BelongsTo<InternalTicketMessage, $this>
     */
    public function replyTo(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reply_to_message_id');
    }

    /**
     * @return HasMany<InternalTicketAttachment, $this>
     */
    public function attachments(): HasMany
    {
        return $this->hasMany(InternalTicketAttachment::class, 'message_id')->orderBy('id');
    }

    public function isRetracted(): bool
    {
        return $this->retracted_at !== null;
    }

    public function isEdited(): bool
    {
        return $this->edited_at !== null;
    }

    /** آخرُ لحظةٍ يملك فيها صاحبُها تعديلها أو سحبها. */
    public function mutableUntil(): ?CarbonInterface
    {
        return $this->created_at?->copy()->addMinutes(self::MUTATION_WINDOW_MINUTES);
    }

    /**
     * لماذا لا يملك هذا الموظف تعديل هذه الرسالة أو سحبها — أو `null` إن ملك.
     *
     * **الترتيبُ مقصود، كبريمولا**: التذكرةُ المغلقة أولاً، ثم الملكية، ثم المهلة. الملكيةُ قبل
     * المهلة كي لا يعرف الغريبُ أمِن المهلة شيءٌ باقٍ لرسالةٍ ليست له.
     *
     * **ولا استثناء للمدير.** هذا يُسأل هنا مباشرةً لا عبر `Gate`: `Gate::before` في
     * AppServiceProvider يمرّر المدير من كل `can()` و`authorize()`، وبريمولا وقعت في هذا الفخ
     * بعينه حين قرّرت أن المدير كغيره.
     *
     * تقرأ `ticket`، فيحمّلها المستدعي.
     */
    public function mutationBlockReason(User $user): ?string
    {
        if (! $this->ticket->status->isOpen()) {
            return 'التذكرة مغلقة';
        }

        if ($this->user_id !== (int) $user->getKey()) {
            return 'هذه الرسالة ليست لك';
        }

        if ($this->isRetracted()) {
            return 'حُذفت هذه الرسالة';
        }

        if (now()->greaterThan($this->mutableUntil())) {
            return 'مضت '.self::MUTATION_WINDOW_MINUTES.' دقيقة على إرسال الرسالة';
        }

        return null;
    }

    /**
     * ما يُقال عن هذه الرسالة في سطرٍ واحد: نصُّها، أو «🎤 رسالة صوتية»، أو «صورة».
     *
     * تقرأ `attachments`، فيحمّلها المستدعي.
     */
    public function previewText(): string
    {
        if ($this->isRetracted()) {
            return self::RETRACTED_PLACEHOLDER;
        }

        if ($this->body !== null && $this->body !== '') {
            return $this->body;
        }

        $first = $this->attachments->first();

        return match ($first?->kind) {
            InternalAttachmentKind::Voice => '🎤 '.InternalAttachmentKind::Voice->label(),
            InternalAttachmentKind::Image => InternalAttachmentKind::Image->label(),
            null => '',
        };
    }
}
