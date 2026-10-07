<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Why a payment's money may not be carried on, or carried back — «تسوية دفعة», TREASURY-DESIGN §٢٣.
 *
 * Each refusal names the field it belongs to, so a sheet settling ten payments at once marks the
 * one row that was refused rather than the whole form.
 */
final class PaymentCannotBeSettled extends DomainException
{
    private ?string $field = null;

    public static function notAPayment(): self
    {
        return new self('تُسوّى الدفعات وحدها — لا الردود ولا القيود');
    }

    public static function reversed(): self
    {
        return new self('هذه الدفعة ملغاة — لا مال فيها يُسوّى');
    }

    public static function predatesTreasury(): self
    {
        return new self('دفعة من قبل الحسابات — لا يُعرف أين نزلت');
    }

    public static function orderSettled(): self
    {
        return new self('الطلبية «تم التسوية» — سُوّي مالها مع الطلبية');
    }

    public static function alreadySettled(): self
    {
        return new self('هذه الدفعة سُوّيت من قبل');
    }

    public static function notSettled(): self
    {
        return new self('هذه الدفعة غير مسوّاة');
    }

    public static function orderSettledCannotUndo(): self
    {
        return new self('الطلبية «تم التسوية» — تراجع عن تسوية الطلبية أولاً');
    }

    public static function missing(): self
    {
        return new self('الدفعة غير موجودة');
    }

    public static function orderMissing(): self
    {
        return new self('الطلبية محذوفة');
    }

    public function onField(string $field): self
    {
        $this->field = $field;

        return $this;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return $this->field === null ? [] : [$this->field => [$this->getMessage()]];
    }
}
