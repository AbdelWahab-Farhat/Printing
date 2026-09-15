<?php

declare(strict_types=1);

namespace App\Domain\Identity\Enums;

/**
 * The roles the *code* knows about by name.
 *
 * Roles themselves live in the database, so the business can add as many as it likes at
 * runtime. This enum only covers the ones something in the codebase has to reference — chiefly
 * Admin, which the authorization gate treats specially. Anything else is data, not a constant.
 */
enum RoleName: string
{
    /** Full access to everything, always — see AppServiceProvider's Gate::before. */
    case Admin = 'admin';

    /** The base employee role. Starts with no permissions; they get granted as needed. */
    case Staff = 'staff';

    /** An example of a job-specific role, ready to have permissions attached to it. */
    case Accountant = 'accountant';

    /**
     * The designer — the one job in this system that is defined by what it may *not* reach.
     *
     * **Seeded with a real starting shape rather than left empty**, which is where it parts from
     * {@see Accountant}. A design ticket is useless without somebody on the other end of it, so
     * shipping the permissions and leaving the role for the administrator to compose would mean
     * the feature does nothing on the day it is deployed. The three grants it starts with — read
     * your own tickets, accept one, upload a version — are the whole of the job.
     *
     * **And it is still data.** Nothing in the code branches on this name: the app decides where
     * to send a designer by asking whether they may accept a ticket and may not read orders, the
     * way it decides an investor's landing screen. The case exists so {@see RoleSeeder} has
     * something to seed, and the administrator may re-shape or delete the role entirely.
     */
    case Designer = 'designer';

    public function label(): string
    {
        return match ($this) {
            self::Admin => 'مدير',
            self::Staff => 'موظف',
            self::Accountant => 'محاسب',
            self::Designer => 'مصمم',
        };
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $role) => $role->value, self::cases());
    }
}
