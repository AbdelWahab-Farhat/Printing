<?php

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Actions\UnsettleOrder;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * Hands `orders.status.unsettle` to every role that can already reverse a payment.
 *
 * **Why those roles and no others.** The only reason to take an order back out of «تم التسوية»
 * is that money on it has to come off again — a payment typed by mistake, a cheque that bounced,
 * a write-off made on the wrong order — and {@see UnsettleOrder} exists because a reversal on a
 * settled order is now refused until somebody does. Whoever the business already trusts to take
 * money off an order is whoever it trusts to reopen it for that purpose; a role that could
 * un-settle but not reverse would hold a key to a door with nothing behind it.
 *
 * Copied from `grant_partial_delivery_to_delivering_roles`, for the same reasons: roles are read
 * from the database rather than named, administrators are covered by the gate, the pivot is
 * written directly, and it runs before `permissions:sync` — hence `findOrCreate`.
 */
return new class extends Migration
{
    public function up(): void
    {
        $unsettle = Permission::findOrCreate(PermissionName::UnsettleOrders->value, 'web');

        $reverse = Permission::query()
            ->where('name', PermissionName::ReverseOrderPayments->value)
            ->where('guard_name', 'web')
            ->first();

        if ($reverse === null) {
            return;
        }

        $rows = DB::table('role_has_permissions')
            ->where('permission_id', $reverse->getKey())
            ->pluck('role_id')
            ->map(fn (int $roleId) => ['role_id' => $roleId, 'permission_id' => $unsettle->getKey()])
            ->all();

        if ($rows !== []) {
            DB::table('role_has_permissions')->insertOrIgnore($rows);
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    /** Only the grant is undone; the permission row belongs to {@see PermissionName}. */
    public function down(): void
    {
        $permission = Permission::query()
            ->where('name', PermissionName::UnsettleOrders->value)
            ->where('guard_name', 'web')
            ->first();

        if ($permission === null) {
            return;
        }

        DB::table('role_has_permissions')->where('permission_id', $permission->getKey())->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
