<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A change that would leave the vendor holding money the company no longer owes them — «لا دفع
 * مقدّم», TREASURY-DESIGN §٢٠. What was paid or credited on the order has to be reversed first.
 */
final class PurchaseOrderIsPaid extends DomainException
{
    public function __construct(string $message, private readonly ?string $field = null)
    {
        parent::__construct($message);
    }

    public static function cannotBeCancelled(string $settled): self
    {
        return new self("على أمر الشراء دفعات وخصومات بـ{$settled} — اعكسها أولاً ثم ألغِ الأمر", 'status');
    }

    public static function totalBelowSettled(string $total, string $settled): self
    {
        return new self("إجمالي الأمر بعد التعديل {$total} أقل مما دُفع عليه وخُصم ({$settled}) — اعكس الزائد أولاً", 'items');
    }

    public static function vendorCannotChange(string $settled): self
    {
        return new self("على أمر الشراء دفعات وخصومات للمورد بـ{$settled} — لا يُنقل إلى مورد آخر قبل عكسها", 'vendor_id');
    }

    public function fieldErrors(): array
    {
        return $this->field === null ? [] : [$this->field => [$this->getMessage()]];
    }
}
