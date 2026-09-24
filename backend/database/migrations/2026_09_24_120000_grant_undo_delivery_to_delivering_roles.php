<?php

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Actions\UndoOrderDelivery;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * Hands `orders.status.undo_delivery` to every role that can already mark an order delivered.
 *
 * Whoever the business trusts to say the customer has the bags is whoever it trusts to say that
 * was a mistake — the same reasoning the reinstatement of a cancellation rides on. Its own grant
 * all the same, because {@see UndoOrderDelivery} takes back the profit the delivery credited to
 * investors, and a switch that can be thrown on its own is what a new power like that deserves.
 *
 * Copied from `grant_partial_delivery_to_delivering_roles`, for the same reasons.
 */
return new class extends Migration
{
    public function up(): void
    {
        $undo = Permission::findOrCreate(PermissionName::UndoOrderDelivery->value, 'web');

        $delivered = Permission::query()
            ->where('name', PermissionName::MarkOrdersDelivered->value)
            ->where('guard_name', 'web')
            ->first();

        if ($delivered === null) {
            return;
        }

        $rows = DB::table('role_has_permissions')
            ->where('permission_id', $delivered->getKey())
            ->pluck('role_id')
            ->map(fn (int $roleId) => ['role_id' => $roleId, 'permission_id' => $undo->getKey()])
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
            ->where('name', PermissionName::UndoOrderDelivery->value)
            ->where('guard_name', 'web')
            ->first();

        if ($permission === null) {
            return;
        }

        DB::table('role_has_permissions')->where('permission_id', $permission->getKey())->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
