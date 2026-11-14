<?php

declare(strict_types=1);

namespace App\Domain\Notification\DTOs;

use App\Domain\Notification\Enums\NotificationType;

/**
 * One notification type on an employee's settings screen, with its switches.
 *
 * A type that is one switch carries a single {@see PushSwitch} whose scope is `''`.
 */
final readonly class PushPreferenceGroup
{
    /**
     * @param  list<PushSwitch>  $switches
     */
    public function __construct(
        public NotificationType $type,
        public array $switches,
    ) {}
}
