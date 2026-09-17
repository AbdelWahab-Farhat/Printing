<?php

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use Database\Seeders\RoleSeeder;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

/**
 * Creates «مصمم» on a system that already exists, holding the three grants the job needs.
 *
 * {@see RoleSeeder} does this for a fresh install and does nothing for a running shop — it is
 * only ever invoked on a database being built. Without this migration a live deployment would
 * gain seven new permissions and nobody holding any of them, so the first designer account could
 * not be created until an administrator built the role by hand from the roles screen. That is a
 * feature that silently does nothing on the day it ships.
 *
 * **Three grants and no more**, and the omissions are the point: no `customers.view`, because a
 * ticket carries the customer's name as a snapshot exactly so that reading one never opens that
 * customer's orders and money; no `design_tickets.view_all`, so a designer sees their own queue
 * and the unclaimed pool rather than a colleague's work; and **no `design_tickets.review`**,
 * because whoever draws the artwork does not sign it off.
 *
 * **Idempotent, and it runs before `permissions:sync` in `deploy.sh`** — hence `findOrCreate` on
 * the permissions rather than a lookup, which on a server whose permission rows are one command
 * behind the code would find nothing and grant nothing.
 *
 * The pivot is written directly rather than through `givePermissionTo`: that reads the role's
 * existing permissions and so trips the application's lazy-loading guard inside a migration.
 * `insertOrIgnore` gives the same idempotence the guard would have.
 */
return new class extends Migration
{
    public function up(): void
    {
        $role = Role::findOrCreate(RoleName::Designer->value, 'web');

        $permissionIds = collect([
            PermissionName::ViewDesignTickets,
            PermissionName::AcceptDesignTickets,
            PermissionName::SubmitDesignTickets,
        ])->map(fn (PermissionName $permission) => Permission::findOrCreate($permission->value, 'web')->getKey());

        DB::table('role_has_permissions')->insertOrIgnore(
            $permissionIds->map(fn (int $permissionId) => [
                'role_id' => $role->getKey(),
                'permission_id' => $permissionId,
            ])->all(),
        );

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    /**
     * The role goes, and the permission rows stay.
     *
     * They are defined by {@see PermissionName} rather than by this migration, and another role
     * the administrator built may already hold one of them. Deleting the role takes its own
     * grants with it through the pivot's cascade, and takes nobody else's.
     *
     * **A role somebody is actually using is left alone.** Removing it would strip every designer
     * account of its access with no record of what it held, and rolling a migration back is
     * supposed to undo a deploy, not re-assign staff.
     */
    public function down(): void
    {
        $role = Role::query()
            ->where('name', RoleName::Designer->value)
            ->where('guard_name', 'web')
            ->first();

        if ($role === null) {
            return;
        }

        if (DB::table('model_has_roles')->where('role_id', $role->getKey())->exists()) {
            return;
        }

        $role->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
