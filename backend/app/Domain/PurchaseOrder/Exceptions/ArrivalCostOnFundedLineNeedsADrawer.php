<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * An arrival cost falls partly on goods investors bought, and was not paid from a drawer.
 *
 * Their share of it becomes the deal's expense (PURCHASE-ORDER-ARRIVAL-COSTS.md, decision 2), and
 * a deal expense is money that left a drawer — on the vendor's bill or owed to somebody else,
 * there is no money for it to have been.
 */
final class ArrivalCostOnFundedLineNeedsADrawer extends DomainException
{
    public function __construct(string $message, private readonly string $field)
    {
        parent::__construct($message);
    }

    public static function make(string $costName, string $field): self
    {
        return new self(
            "«{$costName}» يقع جزءٌ منه على بضاعةٍ ممولة من المستثمرين — حدّد الحساب الذي دُفع منه",
            $field,
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
