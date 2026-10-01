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

    public static function orderCancelled(string $code): self
    {
        return new self("أمر الشراء {$code} ملغى — لا يُدفع عليه", 'purchase_order_id');
    }

    public static function exceedsOrder(string $code, string $remaining): self
    {
        return new self("المتبقي على أمر الشراء {$code} هو {$remaining} — لا يُدفع مقدّماً", 'amount');
    }

    public static function exceedsOwed(string $vendor, string $owed): self
    {
        return new self("المستحق للمورد «{$vendor}» هو {$owed} — لا يُدفع مقدّماً", 'amount');
    }

    public static function alreadyCounted(string $code): self
    {
        return new self("أمر الشراء {$code} محسوبٌ دينه للمورد من قبل");
    }

    public static function nothingToCount(string $code): self
    {
        return new self("أمر الشراء {$code} ملغى أو بلا تكلفة — لا دَين فيه يُحسب");
    }

    public static function debtAlreadyPaid(string $owed): self
    {
        return new self("المستحق للمورد الآن {$owed} — عكس هذا الدَّين يجعل ما دُفع له مقدّماً. اعكس الدفعات أولاً");
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
