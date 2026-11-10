<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Enums;

use App\Domain\Treasury\TreasuryService;

/**
 * The currency an account holds — USD-ACCOUNTS.md §٣.
 *
 * **Every amount on an account is in its currency**: a movement on a dollar account is dollars,
 * and its balance is dollars. Nothing converts on the way in; the one place two currencies meet
 * is «صرف عملة» (`OperationType::Exchange`), which carries both amounts and the rate.
 */
enum Currency: string
{
    case Lyd = 'LYD';
    case Usd = 'USD';

    public function label(): string
    {
        return match ($this) {
            self::Lyd => 'دينار',
            self::Usd => 'دولار',
        };
    }

    /** What is written beside a figure — «د.ل» after it, «$» before it. */
    public function symbol(): string
    {
        return match ($this) {
            self::Lyd => 'د.ل',
            self::Usd => '$',
        };
    }

    /**
     * The kinds an account a person opens in this currency may be. Dinars go anywhere; dollars
     * sit in a cash box or a bank. A vendor's dollar payable is opened by the system alone —
     * {@see TreasuryService::payableForVendor()} — and never through this door.
     */
    public function allows(AccountKind $kind): bool
    {
        return $this === self::Lyd || $kind === AccountKind::Cash || $kind === AccountKind::Bank;
    }

    /**
     * The movement kinds a dollar account takes: what a person does to it by hand, a dollar
     * purchase order's debt (phase 2), paying or crediting that debt (phase 3), and an expense
     * (phase 5). Every other
     * path — a customer's payment, a refund, a settlement, an investor's money — is dinars, and a
     * dollar account reaching one of them is a caller that forgot to refuse it.
     *
     * @return list<MovementKind>
     */
    public static function dollarMovementKinds(): array
    {
        return [
            MovementKind::Opening,
            MovementKind::Deposit,
            MovementKind::Withdrawal,
            MovementKind::Transfer,
            MovementKind::Adjustment,
            MovementKind::Exchange,
            MovementKind::Purchase,
            MovementKind::VendorPayment,
            MovementKind::VendorCredit,
            // Phase 5: an expense in dollars, which carries its dinar figure (`dinar_amount`).
            MovementKind::Expense,
        ];
    }
}
