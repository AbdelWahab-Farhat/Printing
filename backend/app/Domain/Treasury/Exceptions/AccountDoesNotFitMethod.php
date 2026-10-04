<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A chosen account the money could not have landed in — a bank transfer into the cash box, a
 * refund paid out of Nawris's custody, or an account that is switched off.
 */
final class AccountDoesNotFitMethod extends DomainException
{
    public function __construct(string $message, private readonly string $field = 'treasury_account_id')
    {
        parent::__construct($message);
    }

    public static function kind(string $account, string $kind, string $field = 'treasury_account_id'): self
    {
        return new self("الحساب «{$account}» ({$kind}) لا يناسب طريقة الدفع المختارة", $field);
    }

    public static function inactive(string $account, string $field = 'treasury_account_id'): self
    {
        return new self("الحساب «{$account}» معطَّل", $field);
    }

    /** حسابٌ يكتب فيه النظام وحده — النورس — ولا يختاره إنسان. */
    public static function system(string $account, string $field = 'treasury_account_id'): self
    {
        return new self("«{$account}» حسابٌ يكتب فيه النظام وحده — لا يُختار باليد", $field);
    }

    /** عهدةُ شخصٍ آخر: لا يُدخل مالاً في يد زميلٍ لم يستلمه. */
    public static function notYours(string $account, string $field = 'treasury_account_id'): self
    {
        return new self("«{$account}» عهدةُ زميلٍ آخر — لا يُسجَّل فيها إلا صاحبُها", $field);
    }

    public static function custody(string $account, string $field = 'treasury_account_id'): self
    {
        return new self("«{$account}» حساب عهدة — لا يُصرف منه يدوياً، ويُفرَّغ بتسوية الطلبيات", $field);
    }

    public static function payable(string $account, string $field = 'treasury_account_id'): self
    {
        return new self("«{$account}» حساب التزام — ليس فيه مال يُدفع منه", $field);
    }

    public static function vendorPayable(string $account, string $field): self
    {
        return new self("«{$account}» حساب مورد — يتحرك من أوامر الشراء ودفعات المورد وحدها", $field);
    }

    public static function customerExcessPayable(string $account, string $field): self
    {
        return new self("«{$account}» يتحرك من دفعات الطلبيات وحدها — يُردّ الزائد أو يُعتبر إيراداً من شاشة دفعات الطلبية", $field);
    }

    public static function unknownMethod(string $method): self
    {
        return new self("طريقة الدفع «{$method}» غير معروفة للحسابات");
    }

    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
