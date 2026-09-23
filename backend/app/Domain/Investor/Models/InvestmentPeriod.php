<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Investor\Queries\PeriodShares;
use Database\Factories\InvestmentPeriodFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;

/**
 * فترةٌ محاسبية داخل الصندوق المستمرّ — وهي ما يتكرّر، لا الصفقة.
 *
 * تفصيلُ لماذا يخزّن هذا الجدولُ أرقاماً بينما لا يخزّنها شيءٌ آخر في هذه الميزة مكتوبٌ في
 * ترحيله. وما يهمّ هنا: **الصفُّ يُكتب مرّتين في عمره ولا ثالثة** — يوم يُفتح بالرصيد الذي ورثه
 * والمدد المنسوخة، ويوم يُقفَل بأرقامه وعلاماته المائية. وما بينهما يُقرأ ولا يُمسّ.
 *
 * ولا عمود رصيدٍ حيّ عليه: «كم ربحت الفترة الجارية؟» سؤالٌ يُمشى من الدفاتر كما كان دائماً،
 * والأرقامُ هنا جوابُ «كم ربحت فترةٌ أُقفلت؟» — وهما سؤالان لا واحد.
 */
#[UseFactory(InvestmentPeriodFactory::class)]
#[Fillable(['notes'])]
class InvestmentPeriod extends Model implements HasAuditTrail
{
    /** @use HasFactory<InvestmentPeriodFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => PeriodStatus::class,
            'starts_on' => 'date',
            'ends_on' => 'date',
            'subscription_closes_on' => 'date',
            'period_months' => 'integer',
            'subscription_window_days' => 'integer',
            'settlement_months' => 'integer',
            'capital_lock_months' => 'integer',
            'ends_settlement_cycle' => 'boolean',
            'investor_profit_share_percent' => 'decimal:2',
            'opening_stock_cost' => 'decimal:2',
            'opening_cash' => 'decimal:2',
            'closing_stock_cost' => 'decimal:2',
            'closing_cash' => 'decimal:2',
            'sales_revenue' => 'decimal:2',
            'cost_of_goods_sold' => 'decimal:2',
            'cost_damaged' => 'decimal:2',
            'cost_short' => 'decimal:2',
            'expenses_amount' => 'decimal:2',
            'net_profit' => 'decimal:2',
            'investors_pool' => 'decimal:2',
            'company_share' => 'decimal:2',
            'closed_at' => 'datetime',
        ];
    }

    /** «P7» — محجوزٌ قبل الإدراج، كما يُحجز رقم الطلبية ورمز الصفقة. */
    protected static function booted(): void
    {
        static::creating(function (self $period): void {
            if ($period->code === null) {
                $id = (int) DB::scalar(
                    "select nextval(pg_get_serial_sequence('investment_periods', 'id'))"
                );

                $period->id = $id;
                $period->code = 'P'.$id;
            }
        });
    }

    /** الفترةُ التي تستقبل القيد الآن — وهي واحدةٌ أو لا شيء، بحكم فهرسٍ في القاعدة. */
    public static function open(): ?self
    {
        return self::query()->where('status', PeriodStatus::Open)->first();
    }

    /**
     * الفترةُ التي يقع هذا اليومُ في نافذتها — مفتوحةً كانت أو مغلقة.
     *
     * واحدةٌ أو لا شيء، بحكم `EXCLUDE USING gist` على القاعدة: لا يومَ في فترتين. ومن يقرأ منها
     * فترةَ صفٍّ يمرّ بـ{@see PeriodForEntry} لا بها مباشرةً —
     * هذه تقول «أيُّ فترةٍ تسع هذا اليوم»، وتلك تقول «وأيُّها يجوز أن تُكتب فيها اليوم».
     */
    public static function covering(\DateTimeInterface $date): ?self
    {
        return self::query()
            ->whereDate('starts_on', '<=', $date)
            ->whereDate('ends_on', '>=', $date)
            ->first();
    }

    /** أما زال بابُ الاكتتاب مفتوحاً؟ ما يصل بعده يُحتجز إلى الفترة التالية ولا يُنفَق. */
    public function acceptsCapitalOn(\DateTimeInterface $date): bool
    {
        return $this->status === PeriodStatus::Open
            && $date >= $this->starts_on->startOfDay()
            && $date <= $this->subscription_closes_on->endOfDay();
    }

    /**
     * أهذه أوّلُ فترةٍ في عمر الصندوق؟
     *
     * **وهي وحدها التي تُدخَل من نافذتها هي.** نافذةُ الاكتتاب في أول كل فترةٍ بابُ الفترة
     * **التالية** — «ولا تحسب له أرباح شهر تسعة إنما تحسب له أرباح شهر عشرة» — ولا فترةَ قبل
     * الأولى يُكتتب فيها، فلو حُرمت نافذتُها لما كان للصندوق ملّاكٌ في شهره الأول.
     *
     * والسؤالُ عن الفترات لا عن الوحدات: فترةٌ هجرها شركاؤها جميعاً ليست أوّلَ فترة. {@see
     * PeriodShares} يقرأ منها لالتقاط صورة الملّاك، والشاشةُ تقرؤها لتقول لمن يكتتب اليوم متى
     * يبدأ نصيبُه.
     */
    public function isTheFirstOfTheFund(): bool
    {
        return ! self::query()->where('starts_on', '<', $this->starts_on)->exists();
    }

    /** أحلّ موعدُ إقفالها؟ التاريخُ يجعلها مستحقّة، والطلبياتُ الطائرة تقرّر إن كانت تستطيع. */
    public function isDueToClose(\DateTimeInterface $now): bool
    {
        return $this->status === PeriodStatus::Open && $now > $this->ends_on->endOfDay();
    }

    /**
     * كم يوماً مرّ وهي مستحقّةُ الإقفال ولم تُقفَل — أو `null` إن لم تستحقّه بعد.
     *
     * أيامٌ كاملة منذ أوّل لحظةٍ بعد يومها الأخير: صفرٌ في اليوم التالي لنهايتها، وثلاثةٌ بعد
     * ثلاثة أيام. والجدولةُ تُقفلها في ساعتها الأولى، فرقمٌ فوق الصفر على اللوحة يعني أنها صمتت.
     */
    public function daysOverdue(\DateTimeInterface $now): ?int
    {
        if (! $this->isDueToClose($now)) {
            return null;
        }

        return (int) floor($this->ends_on->copy()->addDay()->startOfDay()->diffInDays($now));
    }
}
