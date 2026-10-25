<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Actions\CloseSilentInternalTickets;
use App\Domain\InternalTicket\Enums\InternalTicketPriority;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\Order\Models\Order;
use Database\Factories\InternalTicketFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * محادثةٌ بين موظفَين: مَن فتحها، والزميل الذي وُجّهت إليه.
 *
 * **يراها طرفاها والمدير، ولا يكتب فيها إلا طرفاها** ({@see self::isVisibleTo()} و
 * {@see self::isWritableBy()}). لا صلاحية تُطلب لشيءٍ من هذا، كبريمولا منذ ٢٠٢٦-١٠-١٥: الحكمُ
 * هنا على الصف، لا على مسارٍ بإذن. ومديرٌ ليس طرفاً يقرأ ولا يكتب (السؤال ٥ في §١١، بافتراضه).
 *
 * **لا شيء يحدّد الأطراف أو الحالة قابلٌ للتعبئة**: `opened_by` و`assignee_id` و`status` و`code`
 * ومؤشّرا القراءة ومؤشّرا «قرأتُها» تختمها الأفعال وحدها، فلا يحرّكها جسمُ طلب.
 */
#[UseFactory(InternalTicketFactory::class)]
#[Fillable(['title', 'priority', 'category_id', 'customer_id', 'order_id'])]
class InternalTicket extends Model implements HasAuditTrail
{
    /** @use HasFactory<InternalTicketFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => InternalTicketStatus::class,
            'priority' => InternalTicketPriority::class,
            'opened_by' => 'integer',
            'assignee_id' => 'integer',
            'opener_read_message_id' => 'integer',
            'assignee_read_message_id' => 'integer',
            'opener_seen_message_id' => 'integer',
            'assignee_seen_message_id' => 'integer',
            'last_message_at' => 'datetime',
            'closed_at' => 'datetime',
            'last_reminder_at' => 'datetime',
            'reminder_count' => 'integer',
        ];
    }

    // ─────────────────────────── العلاقات ───────────────────────────

    /**
     * @return BelongsTo<InternalTicketCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(InternalTicketCategory::class, 'category_id');
    }

    /**
     * **بالمؤرشَفين أيضاً** (`withTrashed`) في الثلاثة: موظفٌ أُرشف حسابه يبقى اسمُه على ما قاله وفتحه
     * وأغلقه — المحادثةُ لا تفقد طرفاً لأنه غادر.
     *
     * @return BelongsTo<User, $this>
     */
    public function opener(): BelongsTo
    {
        return $this->belongsTo(User::class, 'opened_by')->withTrashed();
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assignee_id')->withTrashed();
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function closer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closed_by')->withTrashed();
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * المحادثة، الأقدم أولاً — تُقرأ كما تُقرأ المحادثة. ومنها المسحوبة: تبقى مكانها.
     *
     * **`chaperone()`**: كلُّ رسالةٍ تحمل تذكرتها بلا استعلام — المورد يسأل كل رسالةٍ «أيُعدّلها
     * القارئ؟»، والجوابُ يقرأ حالة التذكرة، والوضعُ الصارم يرمي على التحميل الكسول.
     *
     * @return HasMany<InternalTicketMessage, $this>
     */
    public function messages(): HasMany
    {
        return $this->hasMany(InternalTicketMessage::class)->orderBy('id')->chaperone('ticket');
    }

    /**
     * آخرُ رسالةٍ **لم تُسحب** — معاينةُ القائمة، و«مَن ينتظر مَن».
     *
     * المسحوبةُ لا تُعدّ كلاماً: «تم حذف هذه الرسالة» ليست آخر ما قيل، ولا تجعل صاحبها هو من
     * يُنتظر ردّه. كما قرّرت بريمولا في ٢٠٢٦-٠٩-٢٤.
     *
     * @return HasOne<InternalTicketMessage, $this>
     */
    public function latestLiveMessage(): HasOne
    {
        return $this->hasOne(InternalTicketMessage::class)
            ->ofMany(['id' => 'max'], fn ($query) => $query->whereNull('retracted_at'));
    }

    // ─────────────────────────── الأطراف ───────────────────────────

    public function isParty(User $user): bool
    {
        $id = (int) $user->getKey();

        return $this->opened_by === $id || $this->assignee_id === $id;
    }

    /**
     * هل يُعرض هذا الصفُّ على هذا القارئ أصلاً؟ الطرفان والمدير.
     *
     * **والجوابُ «لا» يصير ٤٠٤ لا ٤٠٣**، كتذاكر التصميم: زميلٌ ثالث لا شأن له بأن يعرف أن بين
     * اثنين تذكرة. والقائمة تضيّق بالشرط نفسه في SQL — InternalTicketListQuery.
     */
    public function isVisibleTo(User $user): bool
    {
        return $this->isParty($user) || $user->isAdmin();
    }

    /** يكتب فيها طرفاها، ما دامت مفتوحة. */
    public function isWritableBy(User $user): bool
    {
        return $this->status->isOpen() && $this->isParty($user);
    }

    /** الطرفُ الآخر لهذا الطرف، أو `null` لمن ليس طرفاً. */
    public function counterpartIdOf(User $user): ?int
    {
        $id = (int) $user->getKey();

        return match ($id) {
            $this->opened_by => $this->assignee_id,
            $this->assignee_id => $this->opened_by,
            default => null,
        };
    }

    /**
     * رقمُ آخر رسالةٍ رآها هذا الطرف، أو `null` إن لم يفتحها قط — أو لم يكن طرفاً.
     */
    public function readUpToFor(int $userId): ?int
    {
        return match ($userId) {
            $this->opened_by => $this->opener_read_message_id,
            $this->assignee_id => $this->assignee_read_message_id,
            default => null,
        };
    }

    /** عمودُ مؤشّر القراءة لهذا الطرف. */
    public function readCursorColumnFor(int $userId): ?string
    {
        return match ($userId) {
            $this->opened_by => 'opener_read_message_id',
            $this->assignee_id => 'assignee_read_message_id',
            default => null,
        };
    }

    /**
     * رقمُ آخر رسالةٍ علّمها هذا الطرف بـ«قرأتُها» من بطاقة الرئيسية، أو `null`.
     */
    public function seenUpToFor(int $userId): ?int
    {
        return match ($userId) {
            $this->opened_by => $this->opener_seen_message_id,
            $this->assignee_id => $this->assignee_seen_message_id,
            default => null,
        };
    }

    /** عمودُ مؤشّر «قرأتُها» لهذا الطرف. */
    public function seenCursorColumnFor(int $userId): ?string
    {
        return match ($userId) {
            $this->opened_by => 'opener_seen_message_id',
            $this->assignee_id => 'assignee_seen_message_id',
            default => null,
        };
    }

    /**
     * هل تنتظر هذه التذكرة ردَّ هذا الموظف؟ مفتوحة، وهو طرفٌ فيها، وآخرُ كلامٍ حيٍّ فيها لزميله.
     *
     * **مِن جهتَي التذكرة كلتيهما**، كبريمولا: صاحبُ التذكرة يُنتظر ردّه بقدر ما يُنتظر ردُّ من
     * وُجّهت إليه. ومنه تُبنى بطاقةُ الرئيسية والتذكيرُ كل ساعة، فلا يختلفان.
     *
     * يقرأ `latestLiveMessage`، فيحمّلها المستدعي — الوضع الصارم يرمي على التحميل الكسول.
     */
    public function awaitsReplyFrom(User $user): bool
    {
        if (! $this->status->isOpen() || ! $this->isParty($user)) {
            return false;
        }

        $lastAuthor = $this->latestLiveMessage?->user_id;

        // لا كلام حيّاً فيها — سحب صاحبُها رسالته الأولى — فالدور على من وُجّهت إليه.
        if ($lastAuthor === null) {
            return (int) $user->getKey() === $this->assignee_id;
        }

        return (int) $lastAuthor !== (int) $user->getKey();
    }

    /**
     * هل تنتظر ردَّه **على بطاقة الرئيسية**؟ تنتظره، ولم يعلّمها «قرأتُها» منذ آخر كلامٍ حيٍّ فيها.
     *
     * **رسالةٌ جديدة من زميله تعيدها** — رقمُها أكبر من المؤشّر — وهذا قرارُ المالك (٢٠٢٦-١٠-٢٥).
     * ومنه البطاقةُ وتذكيرُ الصباح، فلا يختلفان: ما أخرجه من بطاقته لا يوقظه به التذكير. والقائمةُ
     * لا تسأله — فيها تبقى «بانتظار ردّك» كما هي.
     *
     * يقرأ `latestLiveMessage`، فيحمّلها المستدعي.
     */
    public function awaitsReplyOnHomeFrom(User $user): bool
    {
        if (! $this->awaitsReplyFrom($user)) {
            return false;
        }

        $seen = $this->seenUpToFor((int) $user->getKey());

        return $seen === null || (int) ($this->latestLiveMessage?->getKey() ?? 0) > $seen;
    }

    /**
     * أُغلقت لأن أحداً من الطرفين لم يكتب ثلاثة أيام — {@see CloseSilentInternalTickets}. لا اسمَ
     * عليها: الإغلاقُ بيد أحدٍ يكتب `closed_by` دائماً.
     */
    public function closedForSilence(): bool
    {
        return ! $this->status->isOpen() && $this->closed_by === null;
    }

    /**
     * كم رسالةً من الطرف الآخر لم يرها هذا الطرف. صفرٌ لمن ليس طرفاً: المدير يقرأ ولا يُحسب له
     * غير مقروء، ولا يحرّك مؤشّر أحد.
     *
     * مشتقٌّ من المؤشّر لا عدّادٌ مخزَّن، للسبب الذي في تذاكر الدعم: العدّاد ينحرف أوّل مرة ينساه
     * مسارٌ واحد. والقائمة تحسبه بالجملة في InternalTicketListQuery بالقاعدة نفسها.
     */
    public function unreadFor(User $user): int
    {
        if (! $this->isParty($user)) {
            return 0;
        }

        $cursor = $this->readUpToFor((int) $user->getKey());

        return $this->messages()
            ->where('user_id', '!=', $user->getKey())
            ->whereNull('retracted_at')
            ->when($cursor !== null, fn ($query) => $query->where('id', '>', $cursor))
            ->count();
    }

    // ─────────────────────────── السجلّ ───────────────────────────

    /**
     * قصةُ التذكرة كاملة: هي، وكل رسالةٍ فيها، وكل ملف.
     *
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        $messageIds = $this->messages()->withTrashed()->pluck('id')->all();

        return [
            $this->getMorphClass() => [$this->getKey()],
            (new InternalTicketMessage)->getMorphClass() => $messageIds,
            (new InternalTicketAttachment)->getMorphClass() => InternalTicketAttachment::query()
                ->withTrashed()
                ->whereIn('message_id', $messageIds)
                ->pluck('id')
                ->all(),
        ];
    }
}
