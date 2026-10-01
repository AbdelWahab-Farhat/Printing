<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Exceptions\VendorPaymentRefused;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Support\Facades\DB;

/**
 * «يُحسب عليه دين للمورد» — an order from before the treasury that is still owed, brought in as if
 * it had been raised after it (TREASURY-DESIGN §٢٠).
 *
 * Every order standing on opening day was marked `predates_treasury` and owes nothing, because
 * nobody knew which of them had been paid. The owner knows; this is how he says so, one order at
 * a time:
 *
 * - its full total goes onto the vendor's «علينا», dated when the order was raised;
 * - what was paid or credited on it since the treasury — which stayed off «علينا» — goes on
 *   too, so an order paid in full nets to nothing;
 * - from then on it is an ordinary order, with «المتبقي» and «لا دفع مقدّم».
 *
 * **One way.** Taking it back out would leave its payments with a debt to come off.
 */
final class CountOldOrderAsDebt
{
    public function __construct(
        private readonly SyncPurchaseOrderDebt $syncDebt,
        private readonly PostVendorPaymentToPayable $postToPayable,
    ) {}

    public function __invoke(PurchaseOrder $order, ?int $actorId): PurchaseOrder
    {
        return DB::transaction(function () use ($order, $actorId): PurchaseOrder {
            // The vendor first, as every payment does — so a payment racing this one waits.
            Vendor::query()->whereKey($order->vendor_id)->lockForUpdate()->first();
            $locked = PurchaseOrder::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            if (! $locked->predates_treasury) {
                throw VendorPaymentRefused::alreadyCounted('#'.$locked->getKey());
            }

            if ($locked->status === PurchaseOrderStatus::Cancelled || $locked->total_amount === null) {
                throw VendorPaymentRefused::nothingToCount('#'.$locked->getKey());
            }

            $locked->forceFill(['predates_treasury' => false])->save();

            ($this->syncDebt)($locked, $actorId);

            VendorPayment::query()
                ->where('purchase_order_id', $locked->getKey())
                ->whereIn('type', [VendorPaymentType::Payment->value, VendorPaymentType::Credit->value])
                ->whereDoesntHave('reversal')
                ->with(['vendor', 'treasuryAccount'])
                ->orderBy('id')
                ->each(fn (VendorPayment $payment) => ($this->postToPayable)($payment));

            return $locked;
        });
    }
}
