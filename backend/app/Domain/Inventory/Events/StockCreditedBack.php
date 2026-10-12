<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Events;

use Illuminate\Foundation\Events\Dispatchable;

/**
 * سحبٌ عُكس، فرجعت وحداتُه إلى **الطبقات نفسها** التي خرجت منها — إلغاءُ طلبية، أو حذفُها، أو
 * إعادةُ سحب سطرٍ عُدِّل.
 *
 * **لماذا يُعلَن:** طبقةٌ رفع مصروفٌ على البضاعة تكلفتَها بعد أن سُحب منها
 * (Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.٥) — الوحداتُ الراجعةُ إليها تحمل الفرقَ في
 * تكلفتها من الآن، فحصتُها التي كُتبت على الطلبية يجب أن تُردّ في اللحظة نفسها، وإلا حُسبت مرّتين.
 *
 * **حدثٌ لا نداء**، للسبب الذي تكتبه أحداثُ الطلبيات: المخزونُ لا يعتمد على الاستثمار. ويُطلق
 * داخل معاملة الحركة نفسها، فالمستمعُ يجري متزامناً — المخزونُ والمالُ يقعان معاً أو لا يقع شيء.
 *
 * `$purchasedLayersToCompany`: الطبقاتُ المسعَّرة لم ترجع — اشترتها المطبعة وذهبت للشركة.
 */
final readonly class StockCreditedBack
{
    use Dispatchable;

    public function __construct(
        public int $reversedMovementId,
        public bool $purchasedLayersToCompany,
    ) {}
}
