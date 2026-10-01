<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\DTOs\VendorPaymentData;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Exceptions\VendorPaymentRefused;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use App\Support\Media\StoreReceipt;
use Illuminate\Support\Facades\DB;

/**
 * Money paid to a vendor — «دفعة للمورد» — or, once, what was already owed on opening day.
 *
 * **A payment is money out by hand**, so the drawer it leaves must hold it — the same guard the
 * treasury's own withdrawals keep (TREASURY-DESIGN §١٢). An opening debt moves no money at all:
 * it only says what the company owed before anybody recorded anything.
 */
final class RecordVendorPayment
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly StoreReceipt $storeReceipt,
    ) {}

    public function __invoke(Vendor $vendor, VendorPaymentData $data, ?User $actor): VendorPayment
    {
        // A counted month stays counted — «مقفل حتى تاريخ» in «إعدادات المالية».
        $this->treasury->guardNotLocked($data->paidAt);

        return DB::transaction(function () use ($vendor, $data, $actor): VendorPayment {
            $locked = Vendor::query()->whereKey($vendor->getKey())->lockForUpdate()->firstOrFail();

            $order = $data->purchaseOrderId === null
                ? null
                : PurchaseOrder::query()->findOrFail($data->purchaseOrderId);

            if ($order !== null && (int) $order->vendor_id !== (int) $locked->getKey()) {
                throw VendorPaymentRefused::orderOfAnotherVendor('#'.$order->getKey());
            }

            $actorId = $actor?->getKey() === null ? null : (int) $actor->getKey();

            $payment = new VendorPayment([
                'amount' => $data->amount,
                'method' => $data->type === VendorPaymentType::Payment ? $data->method : null,
                'reference' => $data->reference,
                'paid_at' => $data->paidAt,
                'notes' => $data->notes,
            ]);

            $payment->vendor_id = $locked->getKey();
            $payment->purchase_order_id = $order?->getKey();
            $payment->type = $data->type;
            $payment->recorded_by = $actorId;

            $account = null;

            if ($data->type === VendorPaymentType::Payment) {
                $account = $this->treasury->accountFor(
                    $data->method->value,
                    $actorId,
                    $data->treasuryAccountId,
                    incoming: false,
                );

                // ولا قبل آخر جردٍ للدرج الذي خرجت منه — الجردُ يشهد بما كان فيه يومها.
                $this->treasury->guardAfterCheckpoint($account, $data->paidAt, 'paid_at');
                $this->treasury->guardCanSpend($account, $data->amount, actorId: $actorId);

                $payment->treasury_account_id = $account->getKey();
            }

            if ($data->receipt !== null) {
                $payment->forceFill(($this->storeReceipt)("vendor-receipts/{$locked->getKey()}", $data->receipt));
            }

            $payment->save();

            if ($account !== null) {
                $this->treasury->post(new MovementData(
                    accountId: (int) $account->getKey(),
                    direction: MovementDirection::Out,
                    kind: MovementKind::VendorPayment,
                    amount: (string) $payment->amount,
                    occurredAt: $payment->paid_at,
                    sourceType: $payment->getMorphClass(),
                    sourceId: (int) $payment->getKey(),
                    notes: "دفعة للمورد {$locked->name}".($order === null ? '' : " — أمر الشراء {$order->getKey()}"),
                    recordedBy: $actorId,
                ));
            }

            return $payment;
        });
    }
}
