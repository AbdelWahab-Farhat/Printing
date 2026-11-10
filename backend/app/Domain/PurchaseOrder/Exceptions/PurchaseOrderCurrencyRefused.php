<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A purchase order's currency rule broken — USD-ACCOUNTS.md §٥ and §٧.
 *
 * A cost on the vendor's bill is in the order's currency; a cost paid from a drawer is in the
 * drawer's, and a dollar drawer pays a dollar order's alone; and a dollar order is received at a
 * rate, which prices its stock in dinars.
 */
final class PurchaseOrderCurrencyRefused extends DomainException
{
    public function __construct(string $message, private readonly string $field)
    {
        parent::__construct($message);
    }

    public static function costOnTheBill(string $currency, string $field): self
    {
        return new self("التكلفة على فاتورة المورد بعملة الأمر — بال{$currency}", $field);
    }

    public static function costInTheDrawers(string $currency, string $field): self
    {
        return new self("عملة التكلفة عملة الحساب الذي دُفعت منه — بال{$currency}", $field);
    }

    /** A dinar order has no rate to bring a dollar cost into its lines. */
    public static function dollarDrawerOnADinarOrder(string $account, string $field): self
    {
        return new self(
            "«{$account}» حسابٌ بالدولار — يدفع تكاليف أوامر الدولار وحدها. ادفعها من حساب بالدينار",
            $field,
        );
    }

    /** «المصاريف» counts a dollar cost in dinars, at the arrival rate or «سعر النظام». */
    public static function noRateForADollarCost(string $field): self
    {
        return new self(
            'لا سعر يُحسب به المصروف بالدينار — اكتب «سعر النظام» في إعدادات المالية أولاً',
            $field,
        );
    }

    public static function arrivalRateNeeded(): self
    {
        return new self(
            'أمر الشراء بالدولار — اكتب سعر الصرف الذي يُسعَّر به المخزون بالدينار',
            'arrival_rate',
        );
    }

    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
