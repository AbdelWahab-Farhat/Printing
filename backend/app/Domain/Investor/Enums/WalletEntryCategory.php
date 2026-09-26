<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

/**
 * The four families a statement is filtered by — what a person asks of their history, not what
 * the ledger needs to know.
 *
 * **A reversal has no family of its own.** It belongs to the family of the row it undoes, so
 * «show me the deposits» also shows the deposit that was taken back; a list that hid the undo
 * would show a deposit the balance does not contain.
 */
enum WalletEntryCategory: string
{
    /** Money crossing the counter as capital: in, or back out. */
    case Capital = 'capital';

    /** Wallet capital going into the fund or a deal, and coming back out of it. */
    case Investment = 'investment';

    /** Profit earned, made withdrawable, paid out, or turned into capital. */
    case Profit = 'profit';

    /** Every shape a loss takes: on an order, off capital, absorbed, carried between periods. */
    case Loss = 'loss';

    public function label(): string
    {
        return match ($this) {
            self::Capital => 'رأس المال',
            self::Investment => 'الاستثمار',
            self::Profit => 'الأرباح',
            self::Loss => 'الخسائر',
        };
    }

    /**
     * @return list<WalletEntryType>
     */
    public function types(): array
    {
        return array_values(array_filter(
            WalletEntryType::cases(),
            fn (WalletEntryType $type) => $type->category() === $this,
        ));
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $category) => $category->value, self::cases());
    }
}
