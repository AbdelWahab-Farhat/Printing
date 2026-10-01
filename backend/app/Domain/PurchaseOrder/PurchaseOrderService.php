<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder;

use App\Domain\Identity\Models\User;
use App\Domain\Inventory\InventoryService;
use App\Domain\PurchaseOrder\Actions\CancelPurchaseOrder;
use App\Domain\PurchaseOrder\Actions\CountOldOrderAsDebt;
use App\Domain\PurchaseOrder\Actions\CreatePurchaseOrder;
use App\Domain\PurchaseOrder\Actions\ReceivePurchaseOrder;
use App\Domain\PurchaseOrder\Actions\RecordVendorPayment;
use App\Domain\PurchaseOrder\Actions\ReversePurchaseOrderReceipt;
use App\Domain\PurchaseOrder\Actions\ReverseVendorPayment;
use App\Domain\PurchaseOrder\Actions\SendPurchaseOrder;
use App\Domain\PurchaseOrder\Actions\UpdatePurchaseOrder;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderData;
use App\Domain\PurchaseOrder\DTOs\ReceivePurchaseOrderData;
use App\Domain\PurchaseOrder\DTOs\ReversePurchaseOrderReceiptData;
use App\Domain\PurchaseOrder\DTOs\VendorPaymentData;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\PurchaseOrder\Queries\PurchaseOrderFilters;
use App\Domain\PurchaseOrder\Queries\PurchaseOrderListQuery;
use App\Domain\PurchaseOrder\Queries\PurchaseOrderStatusCountsQuery;
use App\Domain\PurchaseOrder\Queries\VendorPaymentSummary;
use App\Domain\Vendor\Models\StockArrival;
use App\Domain\Vendor\Models\Vendor;
use App\Domain\Vendor\VendorService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The PurchaseOrder module's public front door.
 *
 * Other modules — today, none; tomorrow, perhaps a reporting context — talk to purchase orders
 * only through this class, the same rule {@see VendorService} and
 * {@see InventoryService} follow. This module depends on Vendor, to post a
 * shipment through {@see receiveArrival()}, and the dependency runs one way — Vendor never
 * imports anything from here.
 */
class PurchaseOrderService
{
    public function __construct(
        private readonly CreatePurchaseOrder $createPurchaseOrder,
        private readonly UpdatePurchaseOrder $updatePurchaseOrder,
        private readonly SendPurchaseOrder $sendPurchaseOrder,
        private readonly CancelPurchaseOrder $cancelPurchaseOrder,
        private readonly ReceivePurchaseOrder $receivePurchaseOrder,
        private readonly ReversePurchaseOrderReceipt $reverseReceipt,
        private readonly PurchaseOrderListQuery $purchaseOrderListQuery,
        private readonly PurchaseOrderStatusCountsQuery $statusCountsQuery,
        private readonly RecordVendorPayment $recordVendorPayment,
        private readonly ReverseVendorPayment $reverseVendorPayment,
        private readonly VendorPaymentSummary $vendorPaymentSummary,
        private readonly CountOldOrderAsDebt $countOldOrderAsDebt,
    ) {}

    /**
     * @return LengthAwarePaginator<int, PurchaseOrder>
     */
    public function paginate(PurchaseOrderFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->purchaseOrderListQuery)($filters, $perPage);
    }

    /**
     * How many orders stand in each status under the same filters the list uses.
     *
     * What a supplier's screen reads its three numbers from in one call — see
     * {@see PurchaseOrderStatusCountsQuery} for why the status filter itself is ignored.
     *
     * @return array<string, int>
     */
    public function statusCounts(PurchaseOrderFilters $filters): array
    {
        return ($this->statusCountsQuery)($filters);
    }

    public function find(int $id): PurchaseOrder
    {
        return PurchaseOrder::query()
            ->with(['vendor', 'warehouse', 'items.stockItem', 'additionalCosts'])
            ->findOrFail($id);
    }

    public function create(PurchaseOrderData $data): PurchaseOrder
    {
        return ($this->createPurchaseOrder)($data);
    }

    public function update(PurchaseOrder $order, PurchaseOrderData $data): PurchaseOrder
    {
        return ($this->updatePurchaseOrder)($order, $data);
    }

    public function send(PurchaseOrder $order): PurchaseOrder
    {
        return ($this->sendPurchaseOrder)($order);
    }

    public function cancel(PurchaseOrder $order): PurchaseOrder
    {
        return ($this->cancelPurchaseOrder)($order);
    }

    /**
     * Posts a shipment against this order and applies it to the order's own lines and status,
     * atomically. See {@see ReceivePurchaseOrder} for how each line reaches both the stock
     * ledger and this order's bookkeeping.
     */
    public function receiveArrival(PurchaseOrder $order, ReceivePurchaseOrderData $data): StockArrival
    {
        return ($this->receivePurchaseOrder)($order, $data);
    }

    /**
     * Takes a receipt entered in error back off the shelf and reopens the order, atomically. See
     * {@see ReversePurchaseOrderReceipt} for what it rolls back here and
     * `Vendor\Actions\ReverseStockArrival` for what it refuses and why.
     */
    public function reverseReceipt(PurchaseOrder $order, ReversePurchaseOrderReceiptData $data): PurchaseOrder
    {
        return ($this->reverseReceipt)($order, $data);
    }

    // ── دفعات الموردين — TREASURY-DESIGN §٨ ──────────────────────────────────────────────

    public function recordVendorPayment(Vendor $vendor, VendorPaymentData $data, ?User $actor): VendorPayment
    {
        return ($this->recordVendorPayment)($vendor, $data, $actor);
    }

    public function reverseVendorPayment(VendorPayment $payment, string $reason, ?User $actor): VendorPayment
    {
        return ($this->reverseVendorPayment)($payment, $reason, $actor);
    }

    /** «يُحسب عليه دين للمورد» — an old order still owed, brought onto «علينا» (§٢٠). */
    public function countOldOrderAsDebt(PurchaseOrder $order, ?User $actor): PurchaseOrder
    {
        return ($this->countOldOrderAsDebt)($order, $actor?->getKey() === null ? null : (int) $actor->getKey());
    }

    /**
     * @return array{ordered: string, opening_debt: string, paid: string, credited: string, owed: string, paid_on_old_orders: string}
     */
    public function vendorPaymentSummary(int $vendorId): array
    {
        return $this->vendorPaymentSummary->forVendor($vendorId);
    }

    /**
     * @return array{total: ?string, paid: string, remaining: ?string, predates_treasury: bool}
     */
    public function purchaseOrderPaymentSummary(PurchaseOrder $order): array
    {
        return $this->vendorPaymentSummary->forPurchaseOrder($order);
    }
}
