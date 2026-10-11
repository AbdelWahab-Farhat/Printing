<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Why money may not move between an order and the customer's wallet as asked.
 * Docs/payments/CUSTOMER-WALLET.md §٤.
 */
final class WalletPaymentRefused extends DomainException
{
    private string $field = 'amount';

    /** «المحفظة» typed into a form that does not check the balance. */
    public static function needsItsOwnDoor(string $field = 'method'): self
    {
        return self::on('الدفع من المحفظة له زرّه: «الدفع من المحفظة»', $field);
    }

    /** A request nobody has accepted yet, or one the shop turned down. */
    public static function notAnOrderYet(string $status): self
    {
        return self::on("الطلبية «{$status}» — لا يُدفع عليها من المحفظة حتى تُقبل", 'amount');
    }

    /** A request key the app already spent on another order — a bug in the client, not a retry. */
    public static function keyUsedOnAnotherOrder(): self
    {
        return self::on('رمز الإرسال استُعمل لدفع طلبيةٍ أخرى — أعد المحاولة', 'client_token');
    }

    /** Nothing left to pay. */
    public static function nothingOwed(): self
    {
        return self::on('لا شيء متبقٍّ على الطلبية', 'amount');
    }

    /**
     * Money paid from the wallet leaves the order only back into it — a cash refund of it would be
     * a withdrawal, and wallets do not pay out (the owner's decision of 2026-10-11).
     */
    public static function refundMustGoToWallet(string $amount, string $refundable): self
    {
        return self::on(
            "لا يُردّ نقداً أكثر من {$refundable} — الباقي دُفع من المحفظة ويُردّ إليها (اختر «المحفظة»)",
            'amount',
        );
    }

    private static function on(string $message, string $field): self
    {
        $exception = new self($message);
        $exception->field = $field;

        return $exception;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
