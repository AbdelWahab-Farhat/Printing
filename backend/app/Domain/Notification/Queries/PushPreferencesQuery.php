<?php

declare(strict_types=1);

namespace App\Domain\Notification\Queries;

use App\Domain\Identity\Models\User;
use App\Domain\Notification\Contracts\GroupNotification;
use App\Domain\Notification\DTOs\PushPreferenceGroup;
use App\Domain\Notification\DTOs\PushSwitch;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\NotificationPreference;

/**
 * An employee's push switches, as the settings screen lists them.
 *
 * **Only the types this employee can receive.** A designer never sees order rows: whether the
 * group reaches them is asked of the gate, which is the same answer `ResolveRecipients` reaches
 * for an administrator and for everyone else.
 *
 * Types appear in catalogue order, and a type added next year appears here the day it implements
 * {@see GroupNotification} — no list to keep in step.
 */
final readonly class PushPreferencesQuery
{
    /**
     * @return list<PushPreferenceGroup>
     */
    public function for(User $user): array
    {
        $saved = NotificationPreference::query()
            ->where('user_id', $user->getKey())
            ->get()
            ->mapWithKeys(fn (NotificationPreference $row) => [$row->type->value.'|'.$row->scope => $row->push]);

        $groups = [];

        foreach (NotificationType::cases() as $type) {
            $definition = app($type->definition());

            if (! $definition instanceof GroupNotification || ! $user->can($definition->groupPermission()->value)) {
                continue;
            }

            $scopes = $definition->pushScopes() ?: ['' => $type->label()];

            $switches = [];

            foreach ($scopes as $scope => $label) {
                $scope = (string) $scope;
                $switches[] = new PushSwitch($scope, $label, (bool) ($saved[$type->value.'|'.$scope] ?? true));
            }

            $groups[] = new PushPreferenceGroup($type, $switches);
        }

        return $groups;
    }
}
