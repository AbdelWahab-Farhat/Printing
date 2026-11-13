<?php

declare(strict_types=1);

namespace App\Domain\Notification\DTOs;

/**
 * One push switch on an employee's notification settings screen.
 */
final readonly class PushSwitch
{
    /**
     * @param  string  $scope  `''` for a type that is one switch, else e.g. an order status value
     */
    public function __construct(
        public string $scope,
        public string $label,
        public bool $push,
    ) {}
}
