<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\Role;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * The permission catalogue, and the roles the system starts with.
 *
 * Permissions come from {@see PermissionName} — the code defines them, because a permission is
 * only real when something checks for it. Roles are seeded with a starting shape and are then
 * entirely the administrator's to change through the API.
 *
 * Idempotent: safe to re-run.
 */
class RoleSeeder extends Seeder
{
    public function run(): void
    {
        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        foreach (RoleName::cases() as $role) {
            Role::findOrCreate($role->value, 'web');
        }

        // The administrator is granted nothing on purpose: the gate in AppServiceProvider gives
        // that role everything, so listing permissions here would be duplicated truth that can
        // drift out of step with the catalogue.

        // A starting point, not a policy — day-to-day staff serve customers but do not set
        // prices or hand out access. Change it from the API; nothing in the code depends on it.
        Role::findByName(RoleName::Staff->value, 'web')->syncPermissions([
            PermissionName::ViewCustomers->value,
            PermissionName::ManageCustomers->value,
            // Not a policy choice: the customer form has a «مجال العمل» picker on every shop
            // row, and it cannot be filled in without the list. Curating that list is the
            // separate, rarer job and stays with the administrator.
            PermissionName::ViewBusinessFields->value,
            PermissionName::ViewProducts->value,
            // Needed to take an order at all — the city and region lists are what an address is
            // chosen from. Curating that map is a separate, rarer job.
            PermissionName::ViewDeliveryLocations->value,
            // Reading stock, not moving it: someone taking an order needs to know whether the
            // size is on the shelf. Recording a transfer or a stocktake is the storekeeper's
            // job, and `inventory.manage` is what the business grants when it decides who that is.
            PermissionName::ViewInventory->value,
        ]);

        // «محاسب» is left deliberately empty — it is the worked example of a role waiting for
        // the business to decide what it may do.

        // Spatie caches roles and permissions; without this, anything created here would be
        // invisible to checks made later in the same process.
        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
}
