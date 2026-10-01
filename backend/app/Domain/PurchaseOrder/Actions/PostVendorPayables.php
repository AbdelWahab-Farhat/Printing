<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\PurchaseOrder\Queries\VendorPaymentSummary;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Support\Facades\DB;

/**
 * Puts what was owed and paid before «علينا» existed on the vendors' payables — TREASURY-DESIGN
 * §٢٠, `treasury:post-vendor-payables`.
 *
 * - Every live order from the treasury on (not `predates_treasury`, not cancelled, with a
 *   total): its debt, dated when it was raised.
 * - Every payment, opening debt and credit that stands (not reversed) and has not reached its
 *   vendor's payable yet: on it, dated when it was paid. A reversed one is left out — it and its
 *   reversal net to nothing, and the drawer already shows both.
 * - A payment or credit on an order from before the treasury stays off the payable; one an
 *   earlier run put there is reversed off it (`unwound`).
 *
 * **Safe to run again**: what is posted is skipped. **A dry run does the same work and rolls it
 * back**, so its figures are exactly what `--apply` writes. Afterwards each vendor's payable must
 * equal the summary's «المستحق» with the sign turned — the report says where it does not.
 */
final class PostVendorPayables
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly SyncPurchaseOrderDebt $syncDebt,
        private readonly VendorPaymentSummary $summary,
        private readonly PostVendorPaymentToPayable $postToPayable,
    ) {}

    /**
     * @return array{
     *     orders: int,
     *     rows: int,
     *     skipped: int,
     *     unwound: int,
     *     vendors: list<array{vendor: string, owed: string, payable: string, matches: bool}>,
     * }
     */
    public function __invoke(bool $apply): array
    {
        // لا يلتقط خطأً (انظر ErrorHandlingTest): خطأٌ في منتصف العمل يترك المعاملةَ بلا commit، فتسقطها
        // القاعدةُ حين ينتهي الأمرُ ويُغلق اتصاله — لا يُكتب نصفُ ترحيل. ولا يناديه غيرُ الأمر.
        DB::beginTransaction();

        $report = $this->post();

        $apply ? DB::commit() : DB::rollBack();

        return $report;
    }

    /**
     * @return array{orders: int, rows: int, skipped: int, unwound: int, vendors: list<array{vendor: string, owed: string, payable: string, matches: bool}>}
     */
    private function post(): array
    {
        $orders = 0;
        $rows = 0;
        $skipped = 0;
        $unwound = 0;

        PurchaseOrder::query()
            ->where('predates_treasury', false)
            ->where('status', '<>', PurchaseOrderStatus::Cancelled->value)
            ->whereNotNull('total_amount')
            ->orderBy('id')
            ->each(function (PurchaseOrder $order) use (&$orders, &$skipped): void {
                $before = $this->liveCount($order->getMorphClass(), (int) $order->getKey());

                ($this->syncDebt)($order, null);

                $before === 0 ? $orders++ : $skipped++;
            });

        VendorPayment::query()
            ->whereIn('type', [VendorPaymentType::Payment->value, VendorPaymentType::OpeningDebt->value, VendorPaymentType::Credit->value])
            ->whereDoesntHave('reversal')
            ->with(['vendor', 'treasuryAccount', 'purchaseOrder'])
            ->orderBy('id')
            ->each(function (VendorPayment $payment) use (&$rows, &$skipped, &$unwound): void {
                // Paying an order from before the treasury stays off the payable. An earlier run
                // of this command put such payments on it; undo that here, so it says «0» again
                // instead of «لنا عنده».
                if (VendorPaymentSummary::isOnAnOldOrder($payment)) {
                    $unwound += $this->unwindFromPayable($payment);

                    return;
                }

                ($this->postToPayable)($payment) ? $rows++ : $skipped++;
            });

        return [
            'orders' => $orders,
            'rows' => $rows,
            'skipped' => $skipped,
            'unwound' => $unwound,
            'vendors' => $this->compare(),
        ];
    }

    /**
     * Reverses what a payment on an old order left on its vendor's payable; the drawer's side
     * stands. Returns how many movements it undid.
     */
    private function unwindFromPayable(VendorPayment $payment): int
    {
        $payableId = $this->treasury->payableIdOfVendor((int) $payment->vendor_id);

        if ($payableId === null) {
            return 0;
        }

        $count = 0;

        foreach ($this->treasury->liveMovementsOf($payment->getMorphClass(), (int) $payment->getKey()) as $movement) {
            if ((int) $movement->account_id !== $payableId) {
                continue;
            }

            $this->treasury->reverseMovement($movement, 'دفعة على أمرٍ قبل النظام — لا تُحسب على «علينا»', null);
            $count++;
        }

        return $count;
    }

    /**
     * Each vendor with a payable: what the summary says is owed, and what the payable says.
     *
     * @return list<array{vendor: string, owed: string, payable: string, matches: bool}>
     */
    private function compare(): array
    {
        $list = [];

        $accounts = TreasuryAccount::query()->whereNotNull('vendor_id')->orderBy('name')->get();
        $names = Vendor::query()->whereIn('id', $accounts->pluck('vendor_id'))->pluck('name', 'id');

        foreach ($accounts as $account) {
            $owed = $this->summary->forVendor((int) $account->vendor_id)['owed'];
            $payable = bcmul($this->treasury->balanceOf($account), '-1', 2);

            $list[] = [
                'vendor' => (string) ($names[$account->vendor_id] ?? $account->name),
                'owed' => $owed,
                'payable' => $payable,
                'matches' => bccomp($owed, $payable, 2) === 0,
            ];
        }

        return $list;
    }

    private function liveCount(string $sourceType, int $sourceId): int
    {
        return $this->treasury->liveMovementsOf($sourceType, $sourceId)->count();
    }
}
