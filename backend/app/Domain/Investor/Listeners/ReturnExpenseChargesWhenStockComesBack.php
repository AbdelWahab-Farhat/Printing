<?php

declare(strict_types=1);

namespace App\Domain\Investor\Listeners;

use App\Domain\Inventory\Events\StockCreditedBack;
use App\Domain\Investor\Actions\LandFundExpenseOnGoods;

/**
 * وحداتٌ رجعت إلى طبقاتٍ يحمل مصروفٌ على البضاعة فرقَه في تكلفتها — فحصتُها التي كُتبت على
 * الطلبية تُردّ.
 *
 * Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.٥. **متزامنٌ لا يُصفّ**، كإخوته: يجري داخل معاملة
 * الحركة نفسها، فرجوعُ الوحدات وردُّ حصتها يقعان معاً أو لا يقع شيء. والغالبُ ألا يجد شيئاً.
 */
final class ReturnExpenseChargesWhenStockComesBack
{
    public function __construct(private readonly LandFundExpenseOnGoods $onGoods) {}

    public function handle(StockCreditedBack $event): void
    {
        $this->onGoods->returnChargesOf($event->reversedMovementId, $event->purchasedLayersToCompany);
    }
}
