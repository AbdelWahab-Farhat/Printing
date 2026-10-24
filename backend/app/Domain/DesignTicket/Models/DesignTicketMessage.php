<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Concerns\CascadesSoftDeletes;
use App\Domain\Identity\Models\User;
use App\Support\Media\ChatAttachmentKind;
use Carbon\CarbonInterface;
use Database\Factories\DesignTicketMessageFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * كلامٌ قيل في محادثة تذكرة تصميم: نصٌّ، أو صورة، أو صوت، أو نصٌّ مع صورته.
 *
 * **نسخةُ `InternalTicketMessage` على تذكرة التصميم**، بقواعدها نفسها (DESIGN-TICKET-CHAT §٣):
 * صاحبُها وحده يعدّلها أو يسحبها، خلال عشرين دقيقة، والتذكرةُ مفتوحة.
 *
 * **`body` وحده قابلٌ للتعبئة**: الكاتبُ يُختم من الموظف المصادَق ولا طريق إلى تغييره، فلا يوقّع
 * جسمُ طلبٍ باسم أحدٍ جملةً لم يقلها. **و`original_body` مخفيٌّ** عن كل `toArray()` وكل مورد.
 */
#[UseFactory(DesignTicketMessageFactory::class)]
#[Fillable(['body'])]
#[Hidden(['original_body'])]
class DesignTicketMessage extends Model
{
    /** @use HasFactory<DesignTicketMessageFactory> */
    use Auditable, CascadesSoftDeletes, HasFactory, SoftDeletes;

    /** مهلةُ التعديل والسحب من لحظة الإرسال، كالتذاكر الداخلية. */
    public const MUTATION_WINDOW_MINUTES = 20;

    /** ما تقوله الرسالة المسحوبة مكانها. */
    public const RETRACTED_PLACEHOLDER = 'تم حذف هذه الرسالة';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'design_ticket_id' => 'integer',
            'edited_at' => 'datetime',
            'retracted_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<DesignTicket, $this>
     */
    public function ticket(): BelongsTo
    {
        return $this->belongsTo(DesignTicket::class, 'design_ticket_id');
    }

    /**
     * بالمؤرشَفين أيضاً: ما قاله موظفٌ غادر يبقى باسمه.
     *
     * @return BelongsTo<User, $this>
     */
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id')->withTrashed();
    }

    /**
     * @return BelongsTo<DesignTicketMessage, $this>
     */
    public function replyTo(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reply_to_message_id');
    }

    /**
     * @return HasMany<DesignTicketMessageAttachment, $this>
     */
    public function attachments(): HasMany
    {
        return $this->hasMany(DesignTicketMessageAttachment::class, 'message_id')->orderBy('id');
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
     * **الترتيبُ مقصود**: التذكرةُ المغلقة أولاً، بجملتها هي، ثم الملكية، ثم المهلة. الملكيةُ قبل
     * المهلة كي لا يعرف الغريبُ أمِن المهلة شيءٌ باقٍ لرسالةٍ ليست له.
     *
     * **ولا استثناء لأحد**، ولا لحامل «إدارة الملاحظات» (السؤال ١). يُسأل هنا مباشرةً لا عبر
     * `Gate`، لأن `Gate::before` يمرّر المدير من كل `can()`.
     *
     * تقرأ `ticket`، فيحمّلها المستدعي.
     */
    public function mutationBlockReason(User $user): ?string
    {
        if (! $this->ticket->acceptsMessages()) {
            return $this->ticket->conversationClosedNote();
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

        return match ($this->attachments->first()?->kind) {
            ChatAttachmentKind::Voice => '🎤 '.ChatAttachmentKind::Voice->label(),
            ChatAttachmentKind::Image => ChatAttachmentKind::Image->label(),
            null => '',
        };
    }

    /**
     * الصورةُ تذهب مع رسالتها حين تُحذف التذكرة. **والسحبُ ليس حذفاً**: لا يلمس `deleted_at`.
     *
     * @return list<string>
     */
    public function softDeleteCascades(): array
    {
        return ['attachments'];
    }
}
