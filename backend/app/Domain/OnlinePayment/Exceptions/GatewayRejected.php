<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * The provider said no — a wrong OTP, a card it refused, a number it does not know.
 *
 * **Its own words reach the customer**, in Arabic as it usually writes them: often the only useful
 * explanation there is.
 */
final class GatewayRejected extends DomainException
{
    private string $field = 'payment';

    public static function make(?string $providerMessage, string $field = 'payment'): self
    {
        $exception = new self($providerMessage !== null && trim($providerMessage) !== ''
            ? trim($providerMessage)
            : 'رفض مزوّد الدفع العملية');
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
