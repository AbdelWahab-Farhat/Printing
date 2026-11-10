<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Queries;

use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\PurchaseOrder\Support\Money;
use App\Domain\Treasury\Enums\Currency;
use Illuminate\Support\Collection;

/**
 * Paid and still owed — for one purchase order, and for a vendor across all of theirs.
 *
 * **A purchase order's total here is what its vendor is owed** — `vendor_amount`: the goods plus
 * the extra costs on the vendor's bill. A cost paid from a drawer or owed to somebody else is out
 * of it (PURCHASE-ORDER-ARRIVAL-COSTS.md) — its own `expense` movement stands for it. «المدفوع»
 * is every live payment recorded against the order. An order from before the treasury (`predates_treasury`) shows what was paid
 * on it and nothing owed: its payments were never recorded, TREASURY-DESIGN §٨.
 *
 * **This is the figure the rules read** — «لا دفع مقدّم» refuses a payment or a credit above
 * it (§٢٠). The vendor's payable in the treasury mirrors it, and nothing moves that payable by
 * hand, so the two agree.
 */
final class VendorPaymentSummary
{
    /**
     * @return array{currency: string, total: ?string, paid: string, credited: string, remaining: ?string, predates_treasury: bool, payable_up_to: ?string}
     */
    public function forPurchaseOrder(PurchaseOrder $order): array
    {
        $rows = VendorPayment::query()->where('purchase_order_id', $order->getKey())->with('reversesPayment')->get();

        $paid = $this->net($rows, VendorPaymentType::Payment);
        $credited = $this->net($rows, VendorPaymentType::Credit);
        $total = $order->vendor_amount === null ? null : (string) $order->vendor_amount;
        $counts = ! $order->predates_treasury && $order->status !== PurchaseOrderStatus::Cancelled && $total !== null;

        $remaining = $counts ? Money::round(bcsub(bcsub($total, $paid, 8), $credited, 8)) : null;

        return [
            // Every figure here is in it — USD-ACCOUNTS.md §٤.
            'currency' => $order->currency->value,
            'total' => $total,
            'paid' => $paid,
            'credited' => $credited,
            'remaining' => $remaining,
            'predates_treasury' => (bool) $order->predates_treasury,
            // The most one payment may be: what is left, or on an order from before the treasury
            // its total less what was paid on it since (§٢٠). Null on a cancelled order.
            'payable_up_to' => match (true) {
                $order->status === PurchaseOrderStatus::Cancelled => null,
                (bool) $order->predates_treasury => $this->leftOnOldOrder($order),
                default => $remaining,
            },
        ];
    }

    /**
     * What the company owes this vendor: every live order's total, plus opening debts, less
     * everything paid and credited — on an order or not.
     *
     * **Except on an order from before the treasury.** Its total was never counted as owed, so
     * what is paid on it cannot count against the rest either: it pays that order's old debt, and
     * is reported apart as `paid_on_old_orders` (§٢٠). The vendor's payable leaves it out alike.
     *
     * **In one currency — dinars unless asked.** A dollar order's debt, and what pays it, is on
     * the vendor's dollar «علينا» (USD-ACCOUNTS.md §٤, §٦); added to the dinars it would be
     * dollars read as dinars. Every order from before the treasury is dinars.
     *
     * @return array{ordered: string, opening_debt: string, paid: string, credited: string, owed: string, paid_on_old_orders: string}
     */
    public function forVendor(int $vendorId, Currency $currency = Currency::Lyd): array
    {
        $ordered = $this->ordered($vendorId, $currency);

        $rows = VendorPayment::query()
            ->where('vendor_id', $vendorId)
            ->where('currency', $currency->value)
            ->with(['reversesPayment', 'purchaseOrder'])
            ->get();

        [$old, $counted] = $rows->partition(fn (VendorPayment $row) => self::isOnAnOldOrder($row));

        $paid = $this->net($counted, VendorPaymentType::Payment);
        $credited = $this->net($counted, VendorPaymentType::Credit);
        $debt = $this->net($counted, VendorPaymentType::OpeningDebt);

        return [
            'ordered' => Money::round($ordered),
            'opening_debt' => $debt,
            'paid' => $paid,
            'credited' => $credited,
            'owed' => Money::round(bcsub(bcsub(bcadd($ordered, $debt, 8), $paid, 8), $credited, 8)),
            'paid_on_old_orders' => Money::round(bcadd(
                $this->net($old, VendorPaymentType::Payment),
                $this->net($old, VendorPaymentType::Credit),
                8,
            )),
        ];
    }

    /**
     * What the company owes this vendor in dollars, on the vendor's dollar «علينا» — the same
     * figures as {@see forVendor()}, in dollars (USD-ACCOUNTS.md §٤, §٦).
     *
     * @return array{ordered: string, opening_debt: string, paid: string, credited: string, owed: string, paid_on_old_orders: string}
     */
    public function dollarsForVendor(int $vendorId): array
    {
        return $this->forVendor($vendorId, Currency::Usd);
    }

    /** Every live order's `vendor_amount` in one currency, from the treasury on. */
    private function ordered(int $vendorId, Currency $currency): string
    {
        return (string) PurchaseOrder::query()
            ->where('vendor_id', $vendorId)
            ->where('currency', $currency->value)
            ->where('predates_treasury', false)
            ->where('status', '<>', PurchaseOrderStatus::Cancelled->value)
            ->sum('vendor_amount');
    }

    /**
     * Whether a row pays an order from before the treasury — outside what the vendor is owed,
     * and outside their payable. A reversal names the same order as the row it undoes.
     */
    public static function isOnAnOldOrder(VendorPayment $row): bool
    {
        return $row->purchase_order_id !== null
            && $row->type !== VendorPaymentType::OpeningDebt
            && (bool) $row->purchaseOrder?->predates_treasury;
    }

    /**
     * What may still be paid on an order from before the treasury: its total, less what was
     * paid and credited on it since. Nothing is known of what was paid before — the cap only
     * stops the order being paid twice over.
     */
    public function leftOnOldOrder(PurchaseOrder $order): string
    {
        $total = $order->vendor_amount === null ? '0' : (string) $order->vendor_amount;

        return Money::round(bcsub($total, $this->settledOn((int) $order->getKey()), 8));
    }

    /**
     * What has been paid and credited on one order, net of reversals — what its total may not
     * fall below, and what stops it being cancelled.
     */
    public function settledOn(int $purchaseOrderId): string
    {
        $rows = VendorPayment::query()->where('purchase_order_id', $purchaseOrderId)->with('reversesPayment')->get();

        return Money::round(bcadd(
            $this->net($rows, VendorPaymentType::Payment),
            $this->net($rows, VendorPaymentType::Credit),
            8,
        ));
    }

    /**
     * The sum of one type's rows, less the reversals of them.
     *
     * @param  Collection<int, VendorPayment>  $rows
     */
    private function net(Collection $rows, VendorPaymentType $type): string
    {
        $total = '0';

        foreach ($rows as $row) {
            if ($row->type === $type) {
                $total = bcadd($total, (string) $row->amount, 8);
            }

            if ($row->type === VendorPaymentType::Reversal && $row->reversesPayment?->type === $type) {
                $total = bcsub($total, (string) $row->amount, 8);
            }
        }

        return Money::round($total);
    }
}
