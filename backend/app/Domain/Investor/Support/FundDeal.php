<?php

declare(strict_types=1);

namespace App\Domain\Investor\Support;

use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Settings\SettingsService;
use Illuminate\Support\Facades\DB;

/**
 * الصندوقُ نفسُه، بوصفه الصفقةَ الدائمة الوحيدة.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٣.
 *
 * ## لماذا صفقةٌ أصلاً، والمالك يقول «لا اريد تحريك موضوع صفقات للمستخدم»
 *
 * لأن **الصفقة هي ختمُ الملكية على البضاعة**: `stock_batches.investor_deal_id` هو ما يعرف به
 * النظامُ كلُّه أنّ هذه الطبقةَ مالُ مستثمرين لا مالُ الشركة — تقرؤه `FundValuation`، و
 * `OrderDealSlices` حين تقسم ربحَ طلبية، و`StockPurchaseMargins` حين تشتري المكينةُ من الرفّ،
 * وكلُّ حارسٍ يمنع بيعَ بضاعةِ غيرك. صندوقٌ بلا ختمٍ كان يعني إعادةَ كتابة ذلك كلِّه.
 *
 * فالصفقةُ **بقيت في القاع وماتت من الشاشة**: صفٌّ واحد لا يُنشئه أحدٌ ولا يراه أحد، تُنسب إليه
 * كلُّ طبقةٍ يشتريها الصندوق، ويُقفَل أبداً. وما يراه المستخدم فتراتٌ ووحدات.
 *
 * ## ونسبةُ الأرباح عليه تُقرأ من الفترة لا منه
 *
 * `investor_profit_share_percent` على صفّه هو الافتراضُ يوم وُلد، و**الحقيقةُ التي تُقسَّم بها
 * فترةٌ منسوخةٌ على صفّها هي** — فمن أُقفل شهرُه على ٥٠٪ يبقى على ٥٠٪ ولو تغيّر الإعداد. ولذلك
 * لا يُحدَّث هذا العمود أبداً بعد الإنشاء.
 *
 * ## وهو لا يُولد من أمر شراء
 *
 * فـ`DealTakesNoMoreCapital` — الذي يرفض مالاً جديداً على صفقةٍ جُمّدت نسبُها يوم تمويلها — لا
 * يمسّه: `isBornFromPurchaseOrder()` كاذبةٌ عليه، وهو بالضبط ما يجعل «صندوقاً يقبل رأسَ مالٍ
 * إلى الأبد» ممكناً بلا حذفِ حارسٍ ما زال يحرس الصفقات القديمة حقّاً.
 */
final class FundDeal
{
    /** الرمزُ المحجوز. رمزُ الصفقات `D{id}`، فلا يصطدم به. */
    public const CODE = 'FUND';

    public function __construct(private readonly SettingsService $settings) {}

    /**
     * الصفقةُ الدائمة — تُنشأ مرّةً في عمر النظام عند أول حاجةٍ إليها.
     *
     * `lockForUpdate` على القراءة الثانية داخل معاملة: إيداعان متزامنان في صندوقٍ جديد يقرآن
     * «لا شيء» معاً، ولولا القفلُ لأنشأ كلٌّ منهما صندوقاً — والفهرسُ الفريد على `code` يرفض
     * الثاني، فيسقط إيداعُ رجلٍ لأن آخر سبقه بجزءٍ من ثانية.
     */
    public function __invoke(): InvestorDeal
    {
        $existing = InvestorDeal::query()->where('code', self::CODE)->first();

        if ($existing !== null) {
            return $existing;
        }

        return DB::transaction(function (): InvestorDeal {
            $existing = InvestorDeal::query()->where('code', self::CODE)->lockForUpdate()->first();

            if ($existing !== null) {
                return $existing;
            }

            $deal = new InvestorDeal;
            $deal->code = self::CODE;
            $deal->status = DealStatus::Open;
            $deal->investor_profit_share_percent = $this->settings->investorProfitSharePercent();
            $deal->opened_on = now()->toDateString();
            $deal->opened_at = now();
            $deal->investor_funded_percent = '100.0000';
            $deal->company_stake = '0.00';
            $deal->save();

            return $deal;
        });
    }

    /** هل هذه الصفقةُ هي الصندوق؟ */
    public function is(InvestorDeal $deal): bool
    {
        return $deal->code === self::CODE;
    }

    /** رقمُه إن وُجد، بلا إنشاء — لمن يقرأ ولا يكتب. */
    public function idOrNull(): ?int
    {
        $id = InvestorDeal::query()->where('code', self::CODE)->value('id');

        return $id === null ? null : (int) $id;
    }
}
