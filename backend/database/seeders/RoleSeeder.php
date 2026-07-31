<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Domain\Identity\Enums\RoleName;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

/**
 * The roles the system starts with.
 *
 * No permissions are attached yet, by design. The administrator does not need any — the gate in
 * AppServiceProvider grants everything to that role — and the rest are empty shells waiting for
 * permissions to be granted as the business decides what each job may do.
 *
 * Roles are ordinary rows, so more can be added at runtime without touching this file.
 *
 * Idempotent: safe to re-run.
 */
class RoleSeeder extends Seeder
{
    public function run(): void
    {
        foreach (RoleName::cases() as $role) {
            Role::findOrCreate($role->value, 'web');
        }

        // Spatie caches roles and permissions; without this a role created here would be
        // invisible to checks made later in the same process, such as the next seeder.
        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
}
