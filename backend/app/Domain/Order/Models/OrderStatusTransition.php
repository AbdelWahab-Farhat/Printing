<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use Database\Factories\OrderStatusTransitionFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One move an order made.
 *
 * Written once and never edited. It still soft deletes and is audited because every model in
 * `app/Domain/` does — a history with an exception in it is a history nobody can trust — but
 * nothing in the application updates one.
 *
 * `from_status` is null exactly once per order: the row recording that it was taken.
 */
#[UseFactory(OrderStatusTransitionFactory::class)]
#[Fillable(['from_status', 'to_status', 'reason', 'user_id'])]
class OrderStatusTransition extends Model
{
    /** @use HasFactory<OrderStatusTransitionFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * الحالات التي يقرأ العميل ما كُتب عندها: «بانتظار المراجعة» و«رُفض الطلب»، لا غير.
     *
     * **كلامُ المراجعة موجّهٌ إليه، وما بعدها كلامُ الورشة لنفسها.** «ناقص ٤٠ كيس» عند «نواقص»
     * أو ما يُكتب عند القبول يُقرأ في تطبيق الموظفين وحده (طلب المستخدم، 2026-09-25).
     *
     * @var list<OrderStatus>
     */
    public const CUSTOMER_NOTE_STATUSES = [OrderStatus::Requested, OrderStatus::RequestRejected];

    /** هل هذا الانتقال ملاحظةٌ يقرؤها العميل: كلامٌ كُتب عند إحدى [CUSTOMER_NOTE_STATUSES]. */
    public function isNoteForCustomer(): bool
    {
        return in_array($this->to_status, self::CUSTOMER_NOTE_STATUSES, true)
            && trim((string) $this->reason) !== '';
    }

    /**
     * الشرط نفسه في الاستعلام — وأيّ تغييرٍ في أحدهما يُغيَّر في الآخر معه.
     *
     * @param  Builder<self>  $query
     */
    public function scopeNotesForCustomer(Builder $query): void
    {
        $query->whereIn('to_status', array_map(fn (OrderStatus $status) => $status->value, self::CUSTOMER_NOTE_STATUSES))
            ->whereNotNull('reason')
            ->whereRaw("trim(reason) <> ''");
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'from_status' => OrderStatus::class,
            'to_status' => OrderStatus::class,
        ];
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
