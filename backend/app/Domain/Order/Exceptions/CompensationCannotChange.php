<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Support\Exceptions\DomainException;

/**
 * Whether an order is a compensation order is settled once its lines close — see
 * `Order::compensationIsEditable()`.
 */
final class CompensationCannotChange extends DomainException
{
    public static function make(OrderStatus $status): self
    {
        return new self("لا يمكن تغيير «طلبية تعويض» وحالة الطلبية «{$status->label()}»");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['is_compensation' => [$this->getMessage()]];
    }
}
