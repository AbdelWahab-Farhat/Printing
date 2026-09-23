<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use DateTimeInterface;
use Illuminate\Support\Facades\DB;

/**
 * لأيّ فترةٍ هذا الصفّ — التعريفُ الواحد الذي يمشي عليه كلُّ من يكتب في دفتر المحافظ.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٢.
 *
 * ```
 * الفترةُ التي يقع تاريخُ المصدر في نافذتها:
 *   · موجودةٌ ومفتوحة  →  هي
 *   · موجودةٌ ومغلقة   →  الفترةُ المفتوحة اليوم        (أرضيةُ التأريخ الرجعي)
 *   · غيرُ موجودة      →  لا شيء — يلتقطها إقفالُ الفترة التي تسع يومَه
 * ```
 *
 * ## لماذا التاريخُ لا لحظةُ الكتابة
 *
 * «كل طلبية في سبتمبر هي ل سبتمبر» — نصُّ قرار المالك. فطلبيةُ ٢٨ سبتمبر التي تُسلَّم في ٢
 * أكتوبر ربحُها لسبتمبر، ولذلك يبقى سبتمبر مفتوحاً للقيد بعد نهاية نافذته حتى تصل آخرُ طلبياته.
 * ولو قُرئ `now()` لذهب ربحُها إلى من دخل بعد أن صُنع.
 *
 * ## ولماذا أرضيةٌ للتأريخ الرجعي
 *
 * سبتمبر أُقفل وخرج مالُه إلى جيوب أصحابه بأرقامٍ مُعلنة. تصحيحُ طلبيةٍ منه في نوفمبر لا يستطيع
 * أن يعود إلى تلك الجيوب — فيقع على **الفترة المفتوحة اليوم**، وهو ما تفعله المحاسبةُ بتصحيح
 * فترةٍ مُقفلة في كل مكان. والبديلُ — رفضُ التصحيح — يترك الخطأ قائماً إلى الأبد.
 *
 * ## ولماذا `null` بابٌ مفتوح لا سهو
 *
 * طلبيةُ ٥ أكتوبر تُسلَّم وسبتمبر ما زال مفتوحاً ينتظر آخرَ طلبياته: **لا فترةَ تسع يومَها بعد**.
 * فترجع `null`، ويُكتب الصفُّ بلا ختم، ويطالب به إقفالُ أكتوبر بنافذته
 * ({@see CloseInvestmentPeriod}). وإسقاطُه على سبتمبر — أقربِ
 * فترةٍ مفتوحة — هو الثقبُ نفسُه الذي جئنا نسدّه، مقلوباً.
 */
final class PeriodForEntry
{
    /** فترةُ صفٍّ مصدرُه شيءٌ له تاريخ — والتاريخُ من ذلك الشيء لا من الساعة. */
    public function bySource(string $sourceType, int $sourceId): ?int
    {
        return $this->byDate($this->dateOf($sourceType, $sourceId));
    }

    /** فترةُ يومٍ بعينه، بعد الأرضية. */
    public function byDate(?DateTimeInterface $date): ?int
    {
        $covering = InvestmentPeriod::covering($date ?? now());

        return $covering === null ? null : $this->floorOf((int) $covering->getKey());
    }

    /**
     * الفترةُ التي يجوز أن يدخلها صفٌّ يخصّ هذه الفترة اليوم.
     *
     * هي هي ما دامت مفتوحة؛ فإذا أُقفلت فالمفتوحةُ اليوم. و`null` تبقى `null` — لأن العكسَ
     * يجب أن يقع حيث وقع أصلُه، فإن كان الأصلُ ينتظر مطالباً انتظر العكسُ معه ونَتَجا صفراً في
     * الفترة نفسها.
     */
    public function floorOf(?int $periodId): ?int
    {
        if ($periodId === null) {
            return null;
        }

        $status = InvestmentPeriod::query()->whereKey($periodId)->value('status');
        $status = $status instanceof PeriodStatus ? $status : PeriodStatus::tryFrom((string) $status);

        // **والمنتظِرةُ تأخذ صفَّها كالمفتوحة.** هذا هو الموضعُ الذي كان يحوّل ربحَ طلبية سبتمبر
        // إلى حَمَلة أكتوبر لو أُقفلت الفترةُ في موعدها: الأرضيةُ كُتبت لتصحيحٍ متأخّرٍ عن فترةٍ
        // **راح مالُها إلى جيوب الناس**، وهي هناك صواب — ولا شيءَ راح من فترةٍ ما زالت تنتظر
        // طلبياتها، فإسقاطُ صفّها على غيرها يسلّم ربحاً لمن لم يموّله.
        if ($status !== null && $status->acceptsPostings()) {
            return $periodId;
        }

        $open = InvestmentPeriod::open();

        return $open === null ? null : (int) $open->getKey();
    }

    /**
     * تاريخُ المصدر — بالعمود الذي تعدّ عليه تقاريرُ الطلبيات نفسها.
     *
     * `coalesce(placed_at, created_at)` هو ما تقرؤه `OrderTotalsQuery` و`FiltersOrders`
     * و`CloseInvestmentPeriod::ordersOf()`، فأرقامُ الصندوق تتّفق مع تقارير الطلبيات بالبناء لا
     * بالمصادفة. وما ليس له تاريخٌ خاصّ — هامشُ المكينة حين تشتري من الرفّ — يقع يومَ وقوعه.
     */
    private function dateOf(string $sourceType, int $sourceId): ?DateTimeInterface
    {
        $raw = match ($sourceType) {
            AuditSubject::Order->value => DB::table('orders')
                ->where('id', $sourceId)
                ->value(DB::raw('coalesce(placed_at, created_at)')),
            AuditSubject::OrderItem->value => DB::table('order_items as oi')
                ->join('orders as o', 'o.id', '=', 'oi.order_id')
                ->where('oi.id', $sourceId)
                ->value(DB::raw('coalesce(o.placed_at, o.created_at)')),
            // **المصروفُ بيوم وقوعه** (`incurred_on`)، لا بيوم إدخال ورقته: فاتورةُ جماركٍ
            // مؤرّخةٌ في سبتمبر تخصّ سبتمبر ولو وصلت المحاسبةَ في أكتوبر. وهو العمودُ نفسه الذي
            // تعدّ عليه `CloseInvestmentPeriod::expensesOf()`.
            AuditSubject::InvestorDealExpense->value => DB::table('investor_deal_expenses')
                ->where('id', $sourceId)
                ->value('incurred_on'),
            default => null,
        };

        return $raw === null ? null : now()->parse($raw);
    }
}
