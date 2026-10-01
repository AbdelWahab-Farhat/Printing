<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Enums;

/**
 * What kind of place the money is in.
 *
 * **`custody` is the one that matters.** Cash, bank and wallet are the company's own; custody is
 * money somebody else is holding *for* the company — Nawris between the doorstep and its
 * transfer, or a driver between the delivery and the handover. It fills when a customer pays and
 * empties when the order is settled, and nothing else touches it — TREASURY-DESIGN §٦.
 *
 * **`payable` is not a place money is at all** — it is what the company owes: a vendor, the owner
 * who lent it cash, the landlord. Its balance runs below zero, −500 being 500 owed, so the same
 * transfers and expenses that move money also move debt — §٢٠.
 */
enum AccountKind: string
{
    case Cash = 'cash';
    case Bank = 'bank';
    case Wallet = 'wallet';
    case Custody = 'custody';
    case Payable = 'payable';

    public function label(): string
    {
        return match ($this) {
            self::Cash => 'خزنة',
            self::Bank => 'مصرف',
            self::Wallet => 'محفظة ليبيانا',
            self::Custody => 'عهدة',
            self::Payable => 'التزام',
        };
    }

    /**
     * Whether money can be *sent* from here by hand — a refund, a vendor payment, a settlement's
     * destination — or fall back into it.
     *
     * Custody empties only through a settlement, which knows which order each dinar belongs to.
     * A hand transfer out of it would leave the per-order sums claiming money that already left.
     * A payable holds no money to send.
     */
    public function spendable(): bool
    {
        return $this === self::Cash || $this === self::Bank || $this === self::Wallet;
    }

    /** Whether the balance is money the company has — everything but a debt. */
    public function holdsMoney(): bool
    {
        return $this !== self::Payable;
    }

    /**
     * The kinds a payment method may land in, the fallback kind first.
     *
     * Takes the method's *value* rather than the Order enum: Treasury is called by Order and must
     * not import it back (RULES §3). An unknown method gets nothing, and the resolver refuses it.
     *
     * @return list<self>
     */
    public static function forMethod(string $method): array
    {
        return match ($method) {
            'cash' => [self::Cash, self::Custody],
            'bank_transfer', 'bank_card' => [self::Bank],
            'libyana' => [self::Wallet],
            default => [],
        };
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $kind) => $kind->value, self::cases());
    }
}
