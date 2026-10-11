<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin PurchaseOrderAdditionalCost
 */
class PurchaseOrderAdditionalCostResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'amount' => (string) $this->amount,
            // Set on a cost typed on the receive screen; null on one planned on the order.
            'stock_arrival_id' => $this->stock_arrival_id,
            // Who was paid: null is the vendor's bill; otherwise the drawer that paid, or the
            // «التزام» it is owed to — `kind` = `payable` says which.
            'treasury_account_id' => $this->treasury_account_id,
            'treasury_account' => $this->whenLoaded('treasuryAccount', fn (): ?array => $this->treasuryAccount === null ? null : [
                'id' => $this->treasuryAccount->id,
                'name' => $this->treasuryAccount->name,
                'kind' => $this->treasuryAccount->kind->value,
            ]),
        ];
    }
}
