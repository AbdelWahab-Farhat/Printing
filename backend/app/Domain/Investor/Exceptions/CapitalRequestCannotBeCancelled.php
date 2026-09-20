<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Only a request that has not taken effect yet can be called off.
 *
 * Once it is applied there is a wallet row behind it and the money has moved; undoing that is a
 * reversal in the ledger, by somebody who has decided to, and not a cancellation of the intention
 * that produced it. The two are different acts and this codebase keeps them apart everywhere money
 * is concerned.
 */
final class CapitalRequestCannotBeCancelled extends DomainException
{
    public static function make(string $status): self
    {
        return new self("هذا الطلب «{$status}» ولا يمكن إلغاؤه");
    }
}
