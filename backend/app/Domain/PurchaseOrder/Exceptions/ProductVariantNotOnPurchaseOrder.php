<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Exceptions;

use App\Domain\Order\Exceptions\DesignDoesNotBelongToCustomer;
use App\Support\Exceptions\DomainException;

/**
 * A received line names a size that was never ordered on this purchase order. A 422 rather than
 * a 404 on purpose: the size exists, it simply is not one of this order's lines — the same
 * reasoning {@see DesignDoesNotBelongToCustomer} carries.
 */
final class ProductVariantNotOnPurchaseOrder extends DomainException
{
    public static function make(int $productVariantId, int $purchaseOrderId): self
    {
        return new self("المقاس رقم {$productVariantId} ليس ضمن بنود أمر الشراء رقم {$purchaseOrderId}");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['items' => [$this->getMessage()]];
    }
}
