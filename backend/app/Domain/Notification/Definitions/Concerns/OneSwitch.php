<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions\Concerns;

use App\Domain\Notification\Contracts\GroupNotification;

/**
 * The common {@see GroupNotification}: the whole type is one push switch, with no finer scope.
 */
trait OneSwitch
{
    /**
     * @return array<string, string>
     */
    public function pushScopes(): array
    {
        return [];
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function pushScopeOf(array $payload): string
    {
        return '';
    }
}
