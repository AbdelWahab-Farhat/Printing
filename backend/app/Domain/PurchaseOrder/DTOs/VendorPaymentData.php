<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\DTOs;

use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Support\Money;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;

/**
 * A payment to a vendor, or an opening debt, as the form sends it.
 */
final readonly class VendorPaymentData
{
    public function __construct(
        public VendorPaymentType $type,
        public string $amount,
        public ?PaymentMethod $method,
        public ?int $purchaseOrderId,
        public ?int $treasuryAccountId,
        public ?string $reference,
        public Carbon $paidAt,
        public ?string $notes,
        public ?UploadedFile $receipt = null,
        // رمزُ الإرسال من التطبيق — الرمزُ نفسه مرّةً ثانية يُرجع الدفعةَ الأولى.
        public ?string $clientToken = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        $text = fn (string $key): ?string => isset($validated[$key]) && trim((string) $validated[$key]) !== ''
            ? trim((string) $validated[$key])
            : null;
        $id = fn (string $key): ?int => isset($validated[$key]) && $validated[$key] !== '' ? (int) $validated[$key] : null;
        $receipt = $validated['receipt'] ?? null;

        return new self(
            type: VendorPaymentType::from((string) ($validated['type'] ?? VendorPaymentType::Payment->value)),
            // One cast at the boundary — JSON hands over `"600"` or `600.5` alike — then a string.
            amount: Money::round(number_format((float) $validated['amount'], 2, '.', '')),
            method: isset($validated['method']) ? PaymentMethod::from((string) $validated['method']) : null,
            purchaseOrderId: $id('purchase_order_id'),
            treasuryAccountId: $id('treasury_account_id'),
            reference: $text('reference'),
            paidAt: $text('paid_at') !== null ? Carbon::parse((string) $validated['paid_at']) : Carbon::now(),
            notes: $text('notes'),
            receipt: $receipt instanceof UploadedFile ? $receipt : null,
            clientToken: $text('client_token'),
        );
    }
}
