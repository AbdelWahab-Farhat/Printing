<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\CloseInvestorDeal;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\Support\FundDeal;
use App\Support\Exceptions\DomainException;

/**
 * الصندوقُ صفٌّ في جدول الصفقات، لا صفقةٌ لها عمرٌ ينتهي.
 *
 * {@see FundDeal} يشرح لماذا بقي في القاع: `investor_deal_id` على
 * طبقة التكلفة هو ختمُ الملكية الذي يقرؤه النظامُ كلُّه. ولأنه بقي صفاً، بقي في متناول كلِّ ما
 * يقبل صفقة — ومنه {@see CloseInvestorDeal}.
 *
 * **وإغلاقُه ليس «صفقةً انتهت» بل صندوقٌ توقّف:** الإقفال يعيد رأسَ مال كلِّ مستثمر إلى محفظته
 * وتبقى وحداتُه قائمة — فيصير له نصيبٌ في صندوقٍ لم يعد ماله فيه — ثم يرفض
 * {@see RecordWalletEntry} كلَّ اشتراكٍ وسحبٍ بعده لأن الصفقة
 * مغلقة. وما يُقفَل في هذا النموذج هو **فترةُ الأرباح**
 * ({@see CloseInvestmentPeriod})، لا الصندوق.
 */
final class TheFundIsNotADeal extends DomainException
{
    public static function closing(): self
    {
        return new self('الصندوق ليس صفقةً تُغلَق — ما يُقفَل هو فترةُ الأرباح');
    }
}
