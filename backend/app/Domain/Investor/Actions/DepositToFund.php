<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\UnitEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\NoPeriodIsOpen;
use App\Domain\Investor\Exceptions\SubscriptionWindowIsClosed;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\UnitPrice;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * مستثمرٌ يدخل الصندوق — البابُ الواحد الذي يكتب في ثلاثة دفاتر.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحتان ٣ و٤.
 *
 * ```
 * دفترُ المحفظة  ←  allocation     رأسُ ماله يخرج من محفظته ويدخل الصندوق
 * دفترُ الخزينة  ←  deposit        نقدٌ صار في يد الصندوق يُشترى به
 * دفترُ الوحدات  ←  issue          ما اشتراه ذلك المال بسعر اليوم
 * ```
 *
 * ## `allocation` لا `deposit` — وهذا قرارُ المالك بنصّه
 *
 * «لا تخلي أحد يقوم بإيداع مال فوق محفظته — مش أي رقم يقبل، لين يكون في محفظة المستثمر.»
 *
 * فالمالُ **يُنقَل** من المحفظة إلى الصندوق ولا يُخلق هنا. والفرقُ ليس تسميةً: `deposit` يزيد
 * رأسَ المال بلا سقف — فمن كان في محفظته ٧٬٦٩٨ ودخل بها الصندوق صار رأسُ ماله ١٥٬٣٩٦، ودخلت
 * الخزينةَ سبعةُ آلافٍ لم تصل المحلَّ مرّتين. و`allocation` يُنقص المحفظة بقدر ما يزيد الصندوق،
 * **وسقفُه يفرضه {@see RecordWalletEntry} من الصفّ المقفول** كما يفرضه لكل سحب.
 *
 * فالمالُ يدخل المحلَّ ببابه القديم (إيداعٌ على الطاولة بطريقة دفع)، ويدخل **الصندوق** من هنا.
 * وهما حدثان مختلفان يقعان في يومين مختلفين، وكانا مدموجين في صفٍّ واحد يكذب على أحدهما.
 *
 * **ولماذا بابٌ واحد لا ثلاثة أزرار.** الثلاثةُ حقيقةٌ واحدة رآها ثلاثةُ شهود. مالٌ ينتقل بلا
 * وحداتٍ يعني رجلاً ماله في الصندوق ولا نصيب له؛ ووحداتٌ بلا نقدٍ في الخزينة تعني حصّةً اشتُريت
 * بهواء. فإمّا أن تقع الثلاثةُ معاً أو لا يقع منها شيء — وهي في معاملةٍ واحدة لذلك.
 *
 * ## والسعرُ يُقرأ قبل أن يدخل ماله
 *
 * {@see UnitPrice} يقسم قيمةَ الصندوق على وحداته، ولو قُرئ بعد كتابة صفّ الخزينة لدخل مالُه في
 * بسط القسمة فاشترى **بسعرٍ رفعه هو**. الترتيبُ هنا ليس ذوقاً: السعرُ أولاً، ثم الدفاتر.
 *
 * ## والنافذةُ والحبس
 *
 * لا يُقبل مالٌ إلا داخلَ نافذة الاكتتاب ({@see SubscriptionWindowIsClosed})، ولا تُصدَّر وحدةٌ
 * بلا فترةٍ مفتوحة ({@see NoPeriodIsOpen}) — فلا سعرَ يُقرأ ولا فترةَ تقاسمه. و`locked_until`
 * يُنسَخ من إعدادات اليوم على **صفّه هو**: «كل deposit Timer خاص به لوحده».
 */
final class DepositToFund
{
    public function __construct(
        private readonly UnitPrice $price,
        private readonly RecordWalletEntry $wallet,
        private readonly RecordCashEntry $cash,
        private readonly FundDeal $fund,
    ) {}

    /**
     * @return array{wallet_entry: InvestorWalletEntry, units: InvestmentUnit}
     */
    public function __invoke(
        int $investorId,
        string $amount,
        ?int $actorId,
        ?string $notes = null,
    ): array {
        return DB::transaction(function () use ($investorId, $amount, $actorId, $notes): array {
            $investor = Investor::query()->whereKey($investorId)->lockForUpdate()->firstOrFail();

            $period = InvestmentPeriod::query()
                ->where('status', PeriodStatus::Open)
                ->lockForUpdate()
                ->first();

            if ($period === null) {
                throw NoPeriodIsOpen::make();
            }

            if (! $period->acceptsCapitalOn(now())) {
                throw SubscriptionWindowIsClosed::make(
                    (string) $period->code,
                    $period->subscription_closes_on->toDateString(),
                    $period->ends_on->copy()->addDay()->toDateString(),
                );
            }

            // **قبل كل كتابة.** انظر الشرح أعلاه.
            $unitPrice = ($this->price)();

            // الصندوقُ يُولد عند أول اشتراك، لا عند تشغيل النظام: صفقةٌ فارغةٌ لا يملكها أحد
            // كانت ستظهر في كل قائمةٍ وكل تقرير قبل أن يدخل دينار.
            $fund = ($this->fund)();

            // والسقفُ يُقرأ هنا من الصفّ المقفول لا من رقمٍ جاء مع الطلب — انضباطُ
            // `RecordOrderPayment` نفسُه: اشتراكان متزامنان بلا قفلٍ يقرآن الرصيد نفسه،
            // فيمرّان معاً ويُخرجان أكثر مما في المحفظة.
            $walletEntry = ($this->wallet)(
                new WalletEntryData(
                    investorId: (int) $investor->getKey(),
                    type: WalletEntryType::Allocation,
                    amount: Money::round($amount),
                    investorDealId: (int) $fund->getKey(),
                    method: null,
                    reference: null,
                    occurredAt: now()->toImmutable(),
                    notes: $notes,
                ),
                $actorId,
            );

            ($this->cash)(
                type: CashEntryType::Deposit,
                amount: Money::round($amount),
                sourceType: AuditSubject::InvestorWalletEntry->value,
                sourceId: (int) $walletEntry->getKey(),
                actorId: $actorId,
            );

            $units = new InvestmentUnit;
            $units->investor_id = $investor->getKey();
            $units->investment_period_id = $period->getKey();
            $units->type = UnitEntryType::Issue;
            $units->units = bcdiv(Money::round($amount), $unitPrice, 6);
            $units->unit_price = $unitPrice;
            $units->amount = Money::round($amount);
            // **من صفّ الفترة لا من الإعدادات.** الفترةُ جمّدت المدةَ يوم فُتحت، فمن دخل في
            // سبتمبر يُحبس مالُه بمدّة سبتمبر ولو تغيّرت في أكتوبر. والسلسلةُ كاملة: الإعدادُ
            // يُنسَخ على الفترة، والفترةُ تُنسَخ على دفعته هو.
            $units->locked_until = now()
                ->addMonths((int) $period->capital_lock_months)
                ->toDateString();
            $units->source_type = AuditSubject::InvestorWalletEntry->value;
            $units->source_id = $walletEntry->getKey();
            $units->occurred_at = now();
            $units->recorded_by = $actorId;
            $units->save();

            return ['wallet_entry' => $walletEntry, 'units' => $units];
        });
    }
}
