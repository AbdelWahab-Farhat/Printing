<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

/**
 * How the money moved.
 *
 * The four the business actually uses. **Required on every entry**, and there is deliberately no
 * `unknown` case: the four cover everything that happens, so a fifth value meaning "nobody
 * asked" would be the one every hurried entry ended up with — and a column that is mostly
 * "unknown" answers no question at all.
 *
 * A cheque is absent because none is taken. Adding one later is a case here and nothing else,
 * which is the whole reason this is an enum rather than a free string.
 */
enum PaymentMethod: string
{
    case Cash = 'cash';

    /** A bank transfer — the reference is the transfer number. */
    case BankTransfer = 'bank_transfer';

    case BankCard = 'bank_card';

    /** Mobile money on Libyana. */
    case Libyana = 'libyana';

    /**
     * «المحفظة» — paid out of, or handed back into, the customer's wallet. No cash moves: the money
     * came in when the wallet was topped up. **Never picked by hand for a payment** — see
     * {@see handPicked()}; a payment from the wallet goes through the one action that checks the
     * balance. Docs/payments/CUSTOMER-WALLET.md §٤.
     */
    case Wallet = 'wallet';

    public function label(): string
    {
        return match ($this) {
            self::Cash => 'كاش',
            self::BankTransfer => 'حوالة',
            self::BankCard => 'بطاقة مصرفية',
            self::Libyana => 'ليبيانا',
            self::Wallet => 'المحفظة',
        };
    }

    /**
     * The methods a person types money in with — every one but the wallet. The payment form, the
     * status screen, a vendor payment and a shortage supply offer these; the wallet has its own
     * door, and a vendor is never paid out of a customer's wallet.
     *
     * @return list<self>
     */
    public static function handPicked(): array
    {
        return array_values(array_filter(self::cases(), fn (self $method) => $method !== self::Wallet));
    }

    /**
     * Whether this method normally comes with a number worth recording.
     *
     * A hint for the form, not a rule the domain enforces: a transfer whose number is not to
     * hand at the counter is still a transfer, and refusing to record it would push the payment
     * onto paper — which is the problem this whole feature exists to end.
     */
    public function suggestsReference(): bool
    {
        return $this !== self::Cash && $this !== self::Wallet;
    }

    /**
     * Whether an entry paid this way must carry its receipt (الواصل).
     *
     * **A transfer, and only a transfer.** Cash is witnessed at the counter, a card leaves a
     * trail at the bank, and Libyana leaves one on the phone. A transfer is the one method whose
     * only proof is a document the customer sends — and a disputed transfer with no document is
     * one person's word against another's.
     *
     * Stated here rather than in the FormRequest so the rule holds for a console command and a
     * future importer too. The request repeats it as a `required_if`, which is what produces the
     * readable field-level 422; the database repeats it a third time as a CHECK, which is what
     * actually guarantees it.
     */
    public function requiresReceipt(): bool
    {
        return $this === self::BankTransfer;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $method) => $method->value, self::cases());
    }
}
