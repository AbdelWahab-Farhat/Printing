<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * مصروفٌ رُبط بطلب شراءٍ لم يُدخل للصندوق بضاعةً — طلبُ الشركة، أو طلبٌ لم يُستلم بعد.
 *
 * لا وحدةَ يتوزّع عليها، فلو قُبل لوقع كلُّه فرقَ تقريبٍ على فترة يومه — أي مصروفَ فترةٍ متنكّراً
 * في مصروفٍ على البضاعة.
 */
final class PurchaseOrderBroughtTheFundNothing extends DomainException
{
    public static function make(int $purchaseOrderId): self
    {
        return new self("أمر الشراء {$purchaseOrderId} لم يُدخل للصندوق بضاعةً مستلمة — لا شيء يُحمَّل عليه المصروف");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['purchase_order_id' => [$this->getMessage()]];
    }
}
