<?php

declare(strict_types=1);

namespace App\Domain\Carrier\DTOs;

use App\Domain\Order\Support\Money;

/**
 * الفرق بين ما عند النورس وما وصل منه، موزَّعاً على الطلبيات.
 *
 * **الفرق هو ما احتفظ به النورس** — لا حاجة لعمود مبالغ من الملف. يصير لكل طلبية
 * `settlement_fee`، فيُقيَّد مصروفاً تحت «رسوم شركة التوصيل» ويعود مع «تراجع عن التسوية».
 *
 * - يساوي الأجور المعروفة: لكل طلبية أجرتها هي، ولا يُسأل عن سبب.
 * - غير ذلك: يُقسم بنسبة مال كل طلبية، ويُطلب سبب — فهذا فرق لا نعرف أصله.
 */
final readonly class NawrisSettlementMoney
{
    /**
     * @param  array<int, string>  $fees  الطلبية => ما احتفظ به النورس منها
     */
    private function __construct(
        public string $difference,
        public array $fees,
        public bool $explained,
    ) {}

    /**
     * @param  array<int, string>  $held  الطلبية => ما عند النورس لها
     * @param  array<int, string>  $knownFees  الطلبية => أجرته المعروفة عليها
     */
    public static function split(array $held, array $knownFees, string $received): self
    {
        $total = Money::sum('0', ...array_values($held));
        $difference = Money::round(bcsub($total, $received, 8));

        if (bccomp($difference, '0', Money::SCALE) <= 0) {
            return new self('0.00', [], true);
        }

        $known = Money::sum('0', ...array_values($knownFees));

        if (bccomp($difference, $known, Money::SCALE) === 0) {
            return new self($difference, $knownFees, true);
        }

        return new self($difference, self::proRata($held, $total, $difference), false);
    }

    /**
     * بالقطع لا بالتقريب، فلا تزيد حصة طلبية على مالها، وما تبقّى من القروش على أكبرها.
     *
     * @param  array<int, string>  $held
     * @return array<int, string>
     */
    private static function proRata(array $held, string $total, string $difference): array
    {
        $shares = [];
        $assigned = '0.00';
        $largest = null;

        foreach ($held as $orderId => $amount) {
            if (bccomp($amount, '0', Money::SCALE) <= 0) {
                continue;
            }

            $share = bcdiv(bcmul($difference, $amount, 8), $total, Money::SCALE);
            $shares[$orderId] = $share;
            $assigned = bcadd($assigned, $share, Money::SCALE);

            if ($largest === null || bccomp($amount, $held[$largest], Money::SCALE) > 0) {
                $largest = $orderId;
            }
        }

        if ($largest !== null) {
            $shares[$largest] = bcadd($shares[$largest], bcsub($difference, $assigned, Money::SCALE), Money::SCALE);
        }

        return $shares;
    }
}
