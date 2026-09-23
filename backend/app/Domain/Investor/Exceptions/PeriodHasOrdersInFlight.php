<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * لا تُقفَل فترةٌ وطلبياتُها لم تصل العملاء بعد.
 *
 * **لأن الطلبية تخصّ فترةَ تاريخها لا فترةَ تسليمها.** طلبيةُ ٢٨ سبتمبر التي تُسلَّم في ٢ أكتوبر
 * ربحُها لسبتمبر، فسبتمبر يبقى مفتوحاً للقيد حتى تصل — وإقفالُه قبلها يقفل على رقمٍ ناقص ثم يأتي
 * الربحُ فلا يجد فترةً يقع فيها.
 *
 * **وطلبيةٌ واحدة عالقة تحبس الفترة ومعها أرباحُ كلّ مستثمريها**، فالبابُ مفتوحٌ بسببٍ يُكتب
 * باسم فاعله على صفّ الفترة — لا تجاوزٌ صامت.
 */
final class PeriodHasOrdersInFlight extends DomainException
{
    /** @param  list<int>  $orderIds */
    public static function make(string $code, array $orderIds): self
    {
        $ids = implode('، ', array_slice($orderIds, 0, 10));
        $more = count($orderIds) > 10 ? ' وغيرها' : '';

        return new self(
            "الفترة «{$code}» فيها طلبيات لم تصل العملاء بعد: {$ids}{$more}"
            .' — تُسلَّم أو تُلغى، أو يُقفَل بتجاوزٍ مُسبَّب'
        );
    }
}
