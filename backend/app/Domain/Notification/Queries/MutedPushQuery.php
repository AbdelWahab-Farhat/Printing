<?php

declare(strict_types=1);

namespace App\Domain\Notification\Queries;

use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\NotificationPreference;

/**
 * Which of a notification's recipients have had its push switched off.
 *
 * One indexed query per publish, whatever the audience size — the same O(1) bargain
 * `ResolveRecipients` makes.
 */
final readonly class MutedPushQuery
{
    /**
     * @param  list<int>  $userIds
     * @return list<int>
     */
    public function among(array $userIds, NotificationType $type, string $scope): array
    {
        if ($userIds === []) {
            return [];
        }

        return NotificationPreference::query()
            ->whereIn('user_id', $userIds)
            ->where('type', $type->value)
            ->where('scope', $scope)
            ->where('push', false)
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }
}
