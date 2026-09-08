<?php

declare(strict_types=1);

namespace App\Domain\Notification\Enums;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\Definitions\ManualAnnouncement;
use App\Domain\Notification\Definitions\OrderReachedShortage;

/**
 * Every kind of notification the system can send — the catalogue.
 *
 * **Adding one is a case here plus a class in `Definitions/`, and nothing else.** No migration,
 * no endpoint, no client release: the app renders whatever `title`, `body`, `icon` and `route`
 * the server hands it, so a type shipped today appears in a build that was compiled last month.
 * That property is the whole design, and the moment something outside this context branches on
 * a `NotificationType` it is gone.
 *
 * The value is *published* — it is written to `notifications.type` and returned by the API — so
 * it is a stable dotted string that must not move when a class is renamed, exactly as
 * {@see AuditSubject} is for morphs.
 */
enum NotificationType: string
{
    /** An order could not be fulfilled from the shelf and is waiting on a person. */
    case OrderShortage = 'order.shortage';

    /** Somebody wrote a message and sent it to staff. The only one a human composes. */
    case Announcement = 'announcement.manual';

    /**
     * The class that knows what this type is about, who hears it and how it reads.
     *
     * A `match` rather than a property on the case, because a definition is resolved from the
     * container — it may need a Service to build its payload — and an enum case cannot hold a
     * constructed object.
     *
     * @return class-string<NotificationDefinition>
     */
    public function definition(): string
    {
        return match ($this) {
            self::OrderShortage => OrderReachedShortage::class,
            self::Announcement => ManualAnnouncement::class,
        };
    }

    /**
     * The icon key the app draws, from a small vocabulary it knows.
     *
     * **A key, never an icon name from any particular toolkit.** The app maps these to whatever
     * its platform draws and falls back to a plain bell on anything it does not recognise, which
     * is what lets a new type ship without the app knowing it exists.
     */
    public function icon(): string
    {
        return match ($this) {
            self::OrderShortage => 'warning',
            self::Announcement => 'announcement',
        };
    }

    /**
     * What this kind of notification is called, for a screen that groups or filters them.
     */
    public function label(): string
    {
        return match ($this) {
            self::OrderShortage => 'نواقص طلبية',
            self::Announcement => 'إشعار عام',
        };
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $type) => $type->value, self::cases());
    }
}
