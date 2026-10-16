<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Wallet\Enums\TopUpMethod;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One row of a customer's wallet, for staff. Docs/payments/CUSTOMER-WALLET.md.
 *
 * `direction` is decided here from the row — a reversal reads the row it undoes — so the app keeps
 * no copy of which types add and which take.
 *
 * @mixin CustomerWalletEntry
 */
class CustomerWalletEntryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $user = $user instanceof User ? $user : null;

        return [
            'id' => $this->id,
            'customer_id' => $this->customer_id,
            'customer' => $this->whenLoaded('customer', fn (): ?array => $this->customer === null ? null : [
                'id' => $this->customer->id,
                'code' => $this->customer->code,
                'name' => $this->customer->name,
                'phone' => $this->customer->phone,
            ]),

            'type' => $this->type->value,
            'type_label' => $this->type->label(),

            /** `in` adds to the wallet, `out` takes from it. */
            'direction' => $this->resource->isCredit() ? 'in' : 'out',

            // Always positive, a string like every money field.
            'amount' => (string) $this->amount,

            // A top-up's alone.
            'method' => $this->method?->value,
            'method_label' => $this->method?->label(),
            'treasury_account' => $this->whenLoaded('treasuryAccount', fn (): ?array => $this->treasuryAccount === null ? null : [
                'id' => $this->treasuryAccount->id,
                'name' => $this->treasuryAccount->name,
            ]),

            // A payment from the wallet, or a refund into it.
            'order_id' => $this->order_id,
            'order_payment_id' => $this->order_payment_id,

            'reference' => $this->reference,
            'notes' => $this->notes,

            'has_receipt' => $this->resource->hasReceipt(),
            'receipt_is_image' => $this->resource->receiptIsImage(),
            'receipt_url' => $this->resource->receiptUrl(),
            'receipt_filename' => $this->receipt_original_filename,

            'occurred_at' => $this->occurred_at?->toIso8601String(),

            'is_reversed' => $this->resource->isReversed(),
            // What puts «عكس» on the row: a top-up or an adjustment, not yet undone, and the grant.
            'can_reverse' => $this->type->isReversibleByHand()
                && $this->method !== TopUpMethod::Online
                && ! $this->resource->isReversed()
                && ($user?->can(PermissionName::ReverseCustomerWalletEntries->value) ?? false),
            'reverses_entry_id' => $this->reverses_entry_id,
            'reversal' => $this->whenLoaded('reversal', fn (): ?array => $this->reversal === null ? null : [
                'id' => $this->reversal->id,
                'reason' => $this->reversal->notes,
                'created_at' => $this->reversal->created_at?->toIso8601String(),
            ]),

            'recorded_by' => $this->recorded_by,
            'recorder' => $this->whenLoaded('recorder', fn (): ?array => $this->recorder === null ? null : [
                'id' => $this->recorder->id,
                'name' => $this->recorder->name,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
