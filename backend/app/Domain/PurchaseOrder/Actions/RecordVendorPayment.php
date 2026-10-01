<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\DTOs\VendorPaymentData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Exceptions\VendorPaymentRefused;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\PurchaseOrder\Queries\VendorPaymentSummary;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use App\Support\Media\StoreReceipt;
use Illuminate\Support\Facades\DB;

/**
 * Money paid to a vendor — «دفعة للمورد» — what was already owed on opening day, or what the
 * vendor knocked off — «خصم من المورد».
 *
 * **A payment is money out by hand**, so the drawer it leaves must hold it — the same guard the
 * treasury's own withdrawals keep (TREASURY-DESIGN §١٢). An opening debt and a credit move no
 * money at all: they only change what is owed.
 *
 * **Every row also lands on the vendor's payable** (§٢٠): a payment and a credit lower the debt,
 * an opening debt raises it. And **nothing is paid or credited in advance**: not more than the
 * vendor is owed, nor more than is left on the order it names. Both are read under the vendor's
 * lock, so two payments cannot each take the last of the debt.
 */
final class RecordVendorPayment
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly StoreReceipt $storeReceipt,
        private readonly VendorPaymentSummary $summary,
    ) {}

    public function __invoke(Vendor $vendor, VendorPaymentData $data, ?User $actor): VendorPayment
    {
        // الضغطةُ الثانية تُجاب قبل أيّ حارس: هي الدفعةُ الأولى نفسها.
        if (($sent = $this->alreadySent($vendor, $data->clientToken)) !== null) {
            return $sent;
        }

        // A counted month stays counted — «مقفل حتى تاريخ» in «إعدادات المالية».
        $this->treasury->guardNotLocked($data->paidAt);

        return DB::transaction(function () use ($vendor, $data, $actor): VendorPayment {
            $locked = Vendor::query()->whereKey($vendor->getKey())->lockForUpdate()->firstOrFail();

            // تحت قفل المورد: ضغطتان متزامنتان تمرّان هنا واحدةً بعد واحدة، ولا يُحفظ واصلٌ مرّتين.
            if (($sent = $this->alreadySent($locked, $data->clientToken)) !== null) {
                return $sent;
            }

            $order = $data->purchaseOrderId === null
                ? null
                : PurchaseOrder::query()->findOrFail($data->purchaseOrderId);

            if ($order !== null && (int) $order->vendor_id !== (int) $locked->getKey()) {
                throw VendorPaymentRefused::orderOfAnotherVendor('#'.$order->getKey());
            }

            if ($data->type !== VendorPaymentType::OpeningDebt) {
                $this->guardNoAdvance($locked, $order, $data->amount);
            }

            $actorId = $actor?->getKey() === null ? null : (int) $actor->getKey();

            $payment = new VendorPayment([
                'amount' => $data->amount,
                'method' => $data->type->movesMoney() ? $data->method : null,
                'reference' => $data->reference,
                'paid_at' => $data->paidAt,
                'notes' => $data->notes,
            ]);

            $payment->vendor_id = $locked->getKey();
            $payment->purchase_order_id = $order?->getKey();
            $payment->type = $data->type;
            $payment->recorded_by = $actorId;
            $payment->client_token = $data->clientToken;

            $account = null;

            if ($data->type->movesMoney()) {
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

            $about = $order === null ? '' : " — أمر الشراء {$order->getKey()}";

            // An order from before the treasury owes nothing on the vendor's payable, so what pays
            // it leaves the drawer and stops there (§٢٠).
            if ($payment->type !== VendorPaymentType::OpeningDebt && (bool) $order?->predates_treasury) {
                if ($account !== null) {
                    $this->post($payment, $account, MovementDirection::Out, MovementKind::VendorPayment, "دفعة للمورد {$locked->name}{$about} (قبل النظام)", $actorId, null);
                }

                return $payment;
            }

            $payable = $this->treasury->payableForVendor((int) $locked->getKey(), (string) $locked->name);

            if ($account !== null) {
                $this->post($payment, $account, MovementDirection::Out, MovementKind::VendorPayment, "دفعة للمورد {$locked->name}{$about}", $actorId, $payable);
            }

            [$direction, $kind, $notes] = match ($data->type) {
                VendorPaymentType::Payment => [MovementDirection::In, MovementKind::VendorPayment, "دفعة من «{$account?->name}»{$about}"],
                VendorPaymentType::Credit => [MovementDirection::In, MovementKind::VendorCredit, "خصم من المورد{$about}"],
                default => [MovementDirection::Out, MovementKind::Opening, 'دَين افتتاحي'],
            };

            $this->post($payment, $payable, $direction, $kind, $notes, $actorId, $account);

            return $payment;
        });
    }

    private function alreadySent(Vendor $vendor, ?string $clientToken): ?VendorPayment
    {
        return $clientToken === null ? null : VendorPayment::query()
            ->where('vendor_id', $vendor->getKey())
            ->where('client_token', $clientToken)
            ->first();
    }

    /**
     * «لا دفع مقدّم» — the owner's rule (§٢٠). Not more than the vendor is owed in all, and not
     * more than is left on the order named. Nothing goes on a cancelled order.
     *
     * **An order from before the treasury is paid on its own terms**: up to its total less what
     * was paid on it since, and apart from the rest of what the vendor is owed — its debt was
     * never counted there.
     */
    private function guardNoAdvance(Vendor $vendor, ?PurchaseOrder $order, string $amount): void
    {
        if ($order !== null && $order->status === PurchaseOrderStatus::Cancelled) {
            throw VendorPaymentRefused::orderCancelled('#'.$order->getKey());
        }

        if ($order !== null && $order->predates_treasury) {
            $left = $this->summary->leftOnOldOrder($order);

            if (bccomp($amount, $left, 2) > 0) {
                throw VendorPaymentRefused::exceedsOrder('#'.$order->getKey(), $left);
            }

            return;
        }

        $remaining = $order === null ? null : $this->summary->forPurchaseOrder($order)['remaining'];

        if ($remaining !== null && bccomp($amount, $remaining, 2) > 0) {
            throw VendorPaymentRefused::exceedsOrder('#'.$order?->getKey(), $remaining);
        }

        $owed = $this->summary->forVendor((int) $vendor->getKey())['owed'];

        if (bccomp($amount, $owed, 2) > 0) {
            throw VendorPaymentRefused::exceedsOwed((string) $vendor->name, $owed);
        }
    }

    private function post(
        VendorPayment $payment,
        TreasuryAccount $account,
        MovementDirection $direction,
        MovementKind $kind,
        string $notes,
        ?int $actorId,
        ?TreasuryAccount $counterpart,
    ): void {
        $this->treasury->post(new MovementData(
            accountId: (int) $account->getKey(),
            direction: $direction,
            kind: $kind,
            amount: (string) $payment->amount,
            occurredAt: $payment->paid_at,
            sourceType: $payment->getMorphClass(),
            sourceId: (int) $payment->getKey(),
            notes: $notes,
            recordedBy: $actorId,
            counterpartAccountId: $counterpart === null ? null : (int) $counterpart->getKey(),
        ));
    }
}
