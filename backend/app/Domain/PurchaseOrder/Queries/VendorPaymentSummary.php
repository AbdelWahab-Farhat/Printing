<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Queries;

use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\PurchaseOrder\Support\Money;
use Illuminate\Support\Collection;

/**
 * Paid and still owed — for one purchase order, and for a vendor across all of theirs.
 *
 * **A purchase order's total is its landed total** — the goods plus the extra costs spread over
 * them — and «المدفوع» is every live payment recorded against it, to the vendor or to whoever
 * carried the goods. An order from before the treasury (`predates_treasury`) shows what was paid
 * on it and nothing owed: its payments were never recorded, TREASURY-DESIGN §٨.
 */
final class VendorPaymentSummary
{
    /**
     * @return array{total: ?string, paid: string, remaining: ?string, predates_treasury: bool}
     */
    public function forPurchaseOrder(PurchaseOrder $order): array
    {
        $paid = $this->paid(VendorPayment::query()->where('purchase_order_id', $order->getKey())->with('reversesPayment')->get());
        $total = $order->total_amount === null ? null : (string) $order->total_amount;
        $counts = ! $order->predates_treasury && $order->status !== PurchaseOrderStatus::Cancelled && $total !== null;

        return [
            'total' => $total,
            'paid' => $paid,
            'remaining' => $counts ? Money::round(bcsub($total, $paid, 8)) : null,
            'predates_treasury' => (bool) $order->predates_treasury,
        ];
    }

    /**
     * What the company owes this vendor: every live order's total, plus opening debts, less
     * everything paid — on an order or not.
     *
     * @return array{ordered: string, opening_debt: string, paid: string, owed: string}
     */
    public function forVendor(int $vendorId): array
    {
        $ordered = (string) PurchaseOrder::query()
            ->where('vendor_id', $vendorId)
            ->where('predates_treasury', false)
            ->where('status', '<>', PurchaseOrderStatus::Cancelled->value)
            ->sum('total_amount');

        $rows = VendorPayment::query()->where('vendor_id', $vendorId)->with('reversesPayment')->get();

        $paid = $this->paid($rows);
        $debt = $this->net($rows, VendorPaymentType::OpeningDebt);

        return [
            'ordered' => Money::round($ordered),
            'opening_debt' => $debt,
            'paid' => $paid,
            'owed' => Money::round(bcsub(bcadd($ordered, $debt, 8), $paid, 8)),
        ];
    }

    /**
     * @param  Collection<int, VendorPayment>  $rows
     */
    private function paid(Collection $rows): string
    {
        return $this->net($rows, VendorPaymentType::Payment);
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
