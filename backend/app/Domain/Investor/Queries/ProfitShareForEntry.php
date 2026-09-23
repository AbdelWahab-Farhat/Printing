<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Support\FundDeal;
use DateTimeInterface;

/**
 * بأيّ نسبةٍ يقتسم المستثمرون نتيجةَ هذا المصدر — التعريفُ الواحد، كما {@see PeriodForEntry}
 * للفترة نفسها.
 *
 * ## الخلافُ الذي وُجد لأجله
 *
 * `investor_profit_share_percent` له **نسختان**: واحدةٌ يكتبها {@see OpenInvestmentPeriod} على
 * كل فترةٍ تُفتح — وهي ما تعرضه لوحةُ الصندوق — وواحدةٌ يكتبها {@see FundDeal} على صفّ الصندوق
 * مرّةً يوم وُلد. و{@see InvestorDeal::investorsCutOf()} كانت تقرأ الثانية، وكلُّ طريقٍ يوصل
 * ديناراً إلى محفظة يمرّ بها.
 *
 * فاتّفق الرقمان ما دام أحدٌ لم يغيّر الإعداد. **وأوّلَ ما يُغيَّر يفترقان بلا صوت:** الفترةُ
 * الجديدة تعرض النسبة الجديدة ويدفع الدفترُ بالقديمة، ولا يظهر ذلك في رقمٍ واحد لأن كلَّ رصيدٍ
 * هنا مشيُ صفوف — ثم تُقفَل الفترةُ فتجمّد القسمةَ القديمة تحت العنوان الجديد.
 *
 * والقاعدةُ الصحيحة مكتوبةٌ في `FundDeal` منذ ولادته: «على صفّه هو الافتراضُ يوم وُلد،
 * **والحقيقةُ التي تُقسَّم بها فترةٌ منسوخةٌ على صفّها هي**». هذا الصنف يجعل النصَّ حكماً.
 *
 * ## والنسبةُ تتبع الفترةَ التي يقع فيها الصفّ، لا فترةَ التاريخ وحدها
 *
 * تُقرأ من {@see PeriodForEntry} نفسِه — بأرضيّته وكلِّ ما فيه — **فالصفُّ ونسبتُه من مشكاةٍ
 * واحدة**. تصحيحٌ متأخّرٌ عن سبتمبر يقع على الفترة المفتوحة اليوم، فيُقسَّم بنسبتها هي؛ ولو
 * قُرئت نسبةُ سبتمبر لصفٍّ يسكن أكتوبر لاختلف عنوانُ الصفّ عن حسابه.
 *
 * ## والصفقةُ القديمة لا تُمسّ
 *
 * نسبتُها عقدٌ جُمّد يوم مولدها ولا فترةَ له؛ وقراءتُها من فترةٍ تعيد كتابة اتفاقٍ وُقِّع عليه.
 * فالفرعُ الأول هنا هو صونُها.
 */
final class ProfitShareForEntry
{
    public function __construct(private readonly PeriodForEntry $periodFor) {}

    /** نسبةُ صفٍّ مصدرُه شيءٌ له تاريخ — طلبيةٌ أو مصروفٌ أو حركةُ مخزون. */
    public function bySource(InvestorDeal $deal, string $sourceType, int $sourceId): string
    {
        if (! $deal->isTheFund()) {
            return (string) $deal->investor_profit_share_percent;
        }

        return $this->ofPeriod($deal, $this->periodFor->bySource($sourceType, $sourceId));
    }

    /** نسبةُ يومٍ بعينه — لمن يعرف التاريخ ولا مصدرَ مسجَّلاً له بعد. */
    public function byDate(InvestorDeal $deal, ?DateTimeInterface $date): string
    {
        if (! $deal->isTheFund()) {
            return (string) $deal->investor_profit_share_percent;
        }

        return $this->ofPeriod($deal, $this->periodFor->byDate($date));
    }

    /**
     * نسبةُ فترةٍ عُرف رقمُها — والسقوطُ إلى صفّ الصندوق حين لا فترة.
     *
     * **و`null` تقع فعلاً**: صفٌّ يُكتب في يومٍ لا تسعه نافذةُ أيّ فترة — بين نهاية نافذةٍ
     * وفتحِ التي تليها — يبقى بلا ختمٍ حتى يطالب به إقفالُ فترته. فحينها الافتراضُ المنسوخ على
     * الصندوق أقربُ ما يوجد، وهو ما كان يُقرأ دائماً قبل هذا الصنف.
     */
    private function ofPeriod(InvestorDeal $deal, ?int $periodId): string
    {
        if ($periodId === null) {
            return (string) $deal->investor_profit_share_percent;
        }

        $percent = InvestmentPeriod::query()
            ->whereKey($periodId)
            ->value('investor_profit_share_percent');

        return $percent === null
            ? (string) $deal->investor_profit_share_percent
            : (string) $percent;
    }
}
