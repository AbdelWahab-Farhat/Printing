<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Support\Exceptions\DomainException;

/**
 * Once the courier has collected, whoever paid the fee has paid it — see
 * `Order::deliveryPayerIsEditable()`.
 */
final class DeliveryPayerCannotChange extends DomainException
{
    public static function make(OrderStatus $status): self
    {
        return new self("لا يمكن تغيير من يدفع التوصيل وحالة الطلبية «{$status->label()}»");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['delivery_paid_by' => [$this->getMessage()]];
    }
}
