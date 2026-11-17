<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Support\Exceptions\DomainException;

/**
 * «أجرة التصميم» locks once the order closes, and a compensation order takes none.
 * See Order::designFeeIsEditable() and ORDER-DESIGN-FEE.md.
 */
final class DesignFeeCannotChange extends DomainException
{
    public static function closed(OrderStatus $status): self
    {
        return new self("لا تُعدَّل أجرة التصميم وحالة الطلبية «{$status->label()}»");
    }

    public static function compensation(): self
    {
        return new self('طلبية التعويض لا تأخذ أجرة تصميم — الزبون لا يدفع شيئاً');
    }

    public static function archived(): self
    {
        return new self('لا تُعدَّل أجرة التصميم على طلبية مؤرشفة');
    }

    public function fieldErrors(): array
    {
        return ['design_fee' => [$this->getMessage()]];
    }
}
