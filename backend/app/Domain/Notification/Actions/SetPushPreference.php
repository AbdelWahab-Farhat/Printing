<?php

declare(strict_types=1);

namespace App\Domain\Notification\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Notification\Contracts\GroupNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Exceptions\NoSuchPushSwitch;
use App\Domain\Notification\Models\NotificationPreference;

/**
 * Turn one push switch on or off for one employee — Docs/notifications/PUSH-PREFERENCES.md.
 *
 * **The row is flipped in place, never deleted.** Switching back on writes `push = true` over the
 * same row, so the audit trail reads as one switch moving rather than rows coming and going.
 *
 * Not checked against what the employee receives today: a role can change tomorrow, and a
 * setting made for a group they have since left does nothing until they rejoin it.
 */
final readonly class SetPushPreference
{
    public function handle(User $user, NotificationType $type, string $scope, bool $push): void
    {
        $this->assertSwitchExists($type, $scope);

        $row = NotificationPreference::query()
            ->where('user_id', $user->getKey())
            ->where('type', $type->value)
            ->where('scope', $scope)
            ->first() ?? new NotificationPreference;

        $row->forceFill([
            'user_id' => $user->getKey(),
            'type' => $type,
            'scope' => $scope,
            'push' => $push,
        ]);

        // A first row saying «on» is the default restated — nothing to record.
        if (! $row->exists && $push) {
            return;
        }

        $row->save();
    }

    private function assertSwitchExists(NotificationType $type, string $scope): void
    {
        $definition = app($type->definition());

        if (! $definition instanceof GroupNotification) {
            throw NoSuchPushSwitch::make();
        }

        $scopes = $definition->pushScopes();

        $valid = $scopes === [] ? $scope === '' : array_key_exists($scope, $scopes);

        if (! $valid) {
            throw NoSuchPushSwitch::make();
        }
    }
}
