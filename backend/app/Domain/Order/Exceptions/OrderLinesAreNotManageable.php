<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Support\Exceptions\DomainException;

/**
 * «إدارة الطلبية» is shut in this status. See {@see Order::linesAreManageable()}.
 */
final class OrderLinesAreNotManageable extends DomainException
{
    public static function make(OrderStatus $status): self
    {
        return new self("لا يمكن تعديل كميات وأسعار الطلبية وهي «{$status->label()}»");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['items' => [$this->getMessage()]];
    }
}
