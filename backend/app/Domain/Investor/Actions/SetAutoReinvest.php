<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Models\Investor;

/**
 * زرُّ «إعادة استثمار الأرباح تلقائياً» — §١٤.
 *
 * لا يحرّك مالاً بنفسه: يكتب الحالة، و`investment:reinvest-profit` يقرؤها في النافذة التالية.
 * و`auto_reinvest_since` يُختم عند التشغيل **ولا يُعاد ختمُه** إن شُغِّل وهو مُشغَّل، ويُمسح عند الإطفاء.
 */
final class SetAutoReinvest
{
    public function __invoke(Investor $investor, bool $enabled): Investor
    {
        if ($enabled === (bool) $investor->auto_reinvest_profit) {
            return $investor;
        }

        $investor->auto_reinvest_profit = $enabled;
        $investor->auto_reinvest_since = $enabled ? now() : null;
        $investor->save();

        return $investor;
    }
}
