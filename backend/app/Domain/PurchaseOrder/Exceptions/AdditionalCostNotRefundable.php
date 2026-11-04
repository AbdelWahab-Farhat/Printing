<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Exceptions;

use App\Domain\PurchaseOrder\Actions\RefundAdditionalCost;
use App\Support\Exceptions\DomainException;

/**
 * This cost has no money that can come back this way — see {@see RefundAdditionalCost}.
 */
final class AdditionalCostNotRefundable extends DomainException
{
    public static function orderStillEditable(): self
    {
        return new self('أمر الشراء ما زال جديداً — عدّل التكلفة أو احذفها من الأمر نفسه فيعود مالها');
    }

    public static function onVendorBill(): self
    {
        return new self('هذه التكلفة على فاتورة المورد، ولم يخرج لها مال من حساب ليُسترد');
    }

    public static function nothingLeft(): self
    {
        return new self('لم يبقَ من هذه التكلفة ما يُسترد');
    }

    public static function moreThanLeft(string $left): self
    {
        return new self("أقصى ما يمكن استرداده من هذه التكلفة {$left}");
    }
}
