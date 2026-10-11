<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\PurchaseOrder;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use Illuminate\Validation\Validator;

/**
 * A purchase order cost charged to a treasury account is money out of it — the same act as
 * «مصروف» on the treasury screen, so it needs the same grant: `treasury.record`.
 *
 * Asked only of what the request would change. Sending back an order whose delivery was already
 * paid from the cash box, with that cost untouched, is not spending — a buyer without the grant
 * may still edit its lines.
 */
final class CostAccountGrant
{
    public static function check(Validator $validator, ?User $user, mixed $costs, ?PurchaseOrder $order = null): void
    {
        if (! is_array($costs) || $user?->can(PermissionName::RecordTreasuryOperations->value)) {
            return;
        }

        $existing = $order === null
            ? collect()
            : $order->additionalCosts()->get()->keyBy(fn (PurchaseOrderAdditionalCost $cost) => (int) $cost->getKey());

        foreach ($costs as $index => $cost) {
            $accountId = is_array($cost) ? ($cost['treasury_account_id'] ?? null) : null;

            if ($accountId === null || $accountId === '') {
                continue;
            }

            /** @var PurchaseOrderAdditionalCost|null $was */
            $was = isset($cost['id']) ? $existing->get((int) $cost['id']) : null;

            $unchanged = $was !== null
                && (int) $was->treasury_account_id === (int) $accountId
                && is_numeric($cost['amount'] ?? null)
                && bccomp((string) $was->amount, number_format((float) $cost['amount'], 2, '.', ''), 2) === 0;

            if (! $unchanged) {
                $validator->errors()->add(
                    "additional_costs.{$index}.treasury_account_id",
                    'الدفع من حساب يحتاج صلاحية «إيداع وسحب ومصروف وتحويل»',
                );
            }
        }
    }
}
