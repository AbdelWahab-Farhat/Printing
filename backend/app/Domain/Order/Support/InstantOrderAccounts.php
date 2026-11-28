<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Exceptions\InstantOrderRefused;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;

/**
 * Which treasury account money taken on an instant order lands in — INSTANT-ORDERS-PLAN.md §7.
 *
 * **The branch decides, and nothing else.** Cash goes into the branch's own box; a transfer or a
 * card into the bank account set on the branch. Unlike every other payment, the person's own
 * account is not tried first (owner's decision, 2026-11-26: the branch setting wins).
 *
 * **A missing setting refuses the payment** rather than falling through to a default — money
 * must not land somewhere nobody chose (§8).
 *
 * **Choosing another account** is its own grant, `instant_orders.choose_account`. The account
 * chosen is still checked by the treasury like any other choice (active, fits the method).
 *
 * The id returned is handed to the treasury as the chosen account, so it is stored on the payment
 * and its movement — changing the branch settings later never moves history.
 */
final class InstantOrderAccounts
{
    /**
     * @throws InstantOrderRefused
     */
    public function resolve(Order $order, PaymentMethod $method, ?int $chosenId, ?User $actor): int
    {
        if ($chosenId !== null) {
            if ($actor?->can(PermissionName::ChooseInstantOrderAccount->value) !== true) {
                throw InstantOrderRefused::accountChoiceNeedsPermission();
            }

            return $chosenId;
        }

        $branch = City::query()->withTrashed()->find($order->city_id);
        $name = (string) ($branch?->name ?? $order->city_name);

        $accountId = match ($method) {
            PaymentMethod::Cash => $branch === null ? null : $this->cashBox((int) $branch->getKey()),
            PaymentMethod::BankTransfer => $branch?->bank_transfer_account_id,
            PaymentMethod::BankCard => $branch?->bank_card_account_id,
            default => null,
        };

        if ($accountId === null) {
            throw InstantOrderRefused::branchHasNoAccount($name, self::methodWord($method));
        }

        return (int) $accountId;
    }

    /** The branch's own cash box — TREASURY-DESIGN §١٩. */
    public function cashBox(int $branchId): ?int
    {
        $id = TreasuryAccount::query()
            ->active()
            ->inDinars()
            ->where('kind', AccountKind::Cash->value)
            ->where('pickup_city_id', $branchId)
            ->value('id');

        return $id === null ? null : (int) $id;
    }

    private static function methodWord(PaymentMethod $method): string
    {
        return match ($method) {
            PaymentMethod::Cash => 'الكاش',
            PaymentMethod::BankTransfer => 'الحوالة',
            PaymentMethod::BankCard => 'البطاقة المصرفية',
            default => $method->label(),
        };
    }
}
