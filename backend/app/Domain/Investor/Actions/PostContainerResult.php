<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\PeriodDistribution;

/**
 * One figure a container's goods earned, sent down whichever road that container is on.
 *
 * **The single fork between the صفقة and the صندوق**, put in one place so the two profit roads —
 * the delivered order ({@see PostDealEarningsForOrder}) and the margin the press pays at the shelf
 * ({@see PostDealStockPurchases}) — do not each have to know about it. Both compute a slice from
 * their own facts and hand it here.
 *
 * ## The two roads differ in *when the cut is taken*, not in what it is
 *
 * ```
 * legacy deal   slice → investorsCutOf() → per-investor rows, now
 * pool          slice → realized earnings, whole → divided at the close
 * ```
 *
 * A deal froze `investor_funded_percent` and `investor_profit_share_percent` when its lorry was
 * funded, so the partners' cut is known the day a sale lands and can be paid immediately. A pool
 * recomputes ownership from capital **at the close**, and its capital weight is not known until the
 * period ends — so the figure is banked whole and divided later.
 *
 * That is why what reaches {@see PostPoolEarning} is the **undivided slice**, and what reaches
 * {@see PostDealShare} has already had the cut applied. Handing a pool the cut figure would apply
 * the investors' share twice: once here, and again in {@see PeriodDistribution}.
 *
 * Both roads are idempotent by comparison, and both express a correction as a further write rather
 * than an edit — each in the shape its road allows.
 */
final class PostContainerResult
{
    public function __construct(
        private readonly PostDealShare $postShare,
        private readonly PostPoolEarning $postEarning,
    ) {}

    /**
     * @param  string  $slice  what the container's goods earned, signed and **undivided**
     * @return list<InvestorWalletEntry> the wallet rows written — always empty for a pool, whose
     *                                   money does not reach an individual until the close
     */
    public function __invoke(
        InvestorDeal $container,
        string $slice,
        string $sourceType,
        int $sourceId,
        string $correctionNote,
    ): array {
        if ($container->isPool()) {
            ($this->postEarning)($container, $slice, $sourceType, $sourceId, $correctionNote);

            return [];
        }

        return ($this->postShare)(
            $container,
            $container->investorsCutOf($slice),
            $sourceType,
            $sourceId,
            $correctionNote,
        );
    }
}
