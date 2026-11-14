<?php

declare(strict_types=1);

namespace App\Domain\Notification\Contracts;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Notification\Audience\AudienceKind;

/**
 * A notification that can go to everyone holding a permission — and whose push an administrator
 * may therefore switch off per employee. Docs/notifications/PUSH-PREFERENCES.md.
 *
 * **Only the group delivery is switchable.** When the same type is addressed to one person by
 * name — a support ticket somebody took, a design ticket given to one designer — the setting is
 * ignored: that is work handed to *them*, and silencing it would break the hand-off. The check
 * lives in `PublishNotification`, on {@see AudienceKind::Permission}, so a definition never has
 * to repeat it.
 *
 * Implemented alongside {@see NotificationDefinition}, never instead of it. A type without this
 * interface always pushes, which is the safe default for everything addressed to a person.
 */
interface GroupNotification
{
    /**
     * Whose group this is — also what decides whether an employee sees the switch at all.
     *
     * The definition's `audience()` returns `permission($this->groupPermission())` for its group
     * case, so the two cannot drift apart.
     */
    public function groupPermission(): PermissionName;

    /**
     * The finer switches inside this type, as value => Arabic label.
     *
     * Empty for a type that is one switch. `order.status` returns the statuses that ring, so an
     * employee can keep «جاهزة» and silence «تم التسوية».
     *
     * @return array<string, string>
     */
    public function pushScopes(): array;

    /**
     * Which of {@see pushScopes()} a published payload falls under — `''` for a type with none.
     *
     * @param  array<string, mixed>  $payload
     */
    public function pushScopeOf(array $payload): string;
}
