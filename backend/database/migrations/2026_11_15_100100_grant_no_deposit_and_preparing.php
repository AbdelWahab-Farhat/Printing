<?php

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * Hands the two new status grants to the roles that already make the neighbouring moves.
 *
 * - `orders.status.no_deposit` to every role holding `orders.status.awaiting_deposit`: whoever
 *   decides whether an order is taken on a عربون gives either answer.
 * - `orders.status.preparing` to every role holding `orders.status.ready_to_print`: the warehouse
 *   desk that hands an order to the press is the one that gathers it first.
 *
 * Without this, «جديدة» would offer no button to anybody but an administrator on the day it
 * ships, because both of its moves are new. Copied from `grant_unsettle_to_payment_reversing_roles`:
 * roles are read from the database rather than named, administrators are covered by the gate,
 * and it runs before `permissions:sync` — hence `findOrCreate`.
 */
return new class extends Migration
{
    /** @var array<string, string> new grant => the grant whose holders receive it */
    private const GRANTS = [
        'orders.status.no_deposit' => 'orders.status.awaiting_deposit',
        'orders.status.preparing' => 'orders.status.ready_to_print',
    ];

    public function up(): void
    {
        foreach (self::GRANTS as $new => $existing) {
            $granted = Permission::findOrCreate($new, 'web');

            $source = Permission::query()
                ->where('name', $existing)
                ->where('guard_name', 'web')
                ->first();

            if ($source === null) {
                continue;
            }

            $rows = DB::table('role_has_permissions')
                ->where('permission_id', $source->getKey())
                ->pluck('role_id')
                ->map(fn (int $roleId) => ['role_id' => $roleId, 'permission_id' => $granted->getKey()])
                ->all();

            if ($rows !== []) {
                DB::table('role_has_permissions')->insertOrIgnore($rows);
            }
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    /** Only the grants are undone; the permission rows belong to {@see PermissionName}. */
    public function down(): void
    {
        $ids = Permission::query()
            ->whereIn('name', array_keys(self::GRANTS))
            ->where('guard_name', 'web')
            ->pluck('id');

        DB::table('role_has_permissions')->whereIn('permission_id', $ids)->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
