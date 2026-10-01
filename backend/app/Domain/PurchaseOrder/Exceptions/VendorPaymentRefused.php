<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Exceptions;

use App\Support\Exceptions\DomainException;

final class VendorPaymentRefused extends DomainException
{
    public function __construct(string $message, private readonly ?string $field = null)
    {
        parent::__construct($message);
    }

    public static function orderOfAnotherVendor(string $code): self
    {
        return new self("أمر الشراء {$code} ليس لهذا المورد", 'purchase_order_id');
    }

    public static function cannotBeReversed(): self
    {
        return new self('هذه الحركة لا تُعكس — هي عكسٌ لغيرها أو معكوسة من قبل');
    }

    public static function notThisVendors(): self
    {
        return new self('هذه الدفعة ليست لهذا المورد');
    }

    public function fieldErrors(): array
    {
        return $this->field === null ? [] : [$this->field => [$this->getMessage()]];
    }
}
