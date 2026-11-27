<?php

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\Role;
use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * Registers the instant-order and branch permissions, and creates the «موظف الفرع» role
 * (INSTANT-ORDERS-PLAN.md §9).
 *
 * The role is a starting point the owner edits on the roles screen, like every seeded role. It
 * reads every order, sells, hands over and records the money taken — and nothing else: no normal
 * order, no standalone customer, no production status, no settlement, no stock edit.
 * `instant_orders.choose_account` and `branches.manage` are granted to nobody; an administrator
 * holds them through `Gate::before`.
 */
return new class extends Migration
{
    private const ROLE = 'موظف الفرع';

    /** @var list<PermissionName> */
    private const NEW_PERMISSIONS = [
        PermissionName::ViewInstantOrders,
        PermissionName::CreateInstantOrders,
        PermissionName::UpdateInstantOrders,
        PermissionName::CancelInstantOrders,
        PermissionName::DeliverInstantOrders,
        PermissionName::ChooseInstantOrderAccount,
        PermissionName::DeliverBranchPickupOrders,
        PermissionName::ManageBranches,
    ];

    /** @var list<PermissionName> */
    private const ROLE_PERMISSIONS = [
        PermissionName::ViewOrders,
        PermissionName::ViewInstantOrders,
        PermissionName::CreateInstantOrders,
        PermissionName::UpdateInstantOrders,
        PermissionName::CancelInstantOrders,
        PermissionName::DeliverInstantOrders,
        PermissionName::DeliverBranchPickupOrders,
        PermissionName::RecordOrderPayments,
        // The city and region pickers for the customer's address on the instant form.
        PermissionName::ViewDeliveryLocations,
    ];

    public function up(): void
    {
        foreach (self::NEW_PERMISSIONS as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        // The two it borrows may not exist yet on a fresh database: this runs before
        // `permissions:sync`.
        foreach (self::ROLE_PERMISSIONS as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();

        Role::findOrCreate(self::ROLE, 'web')->givePermissionTo(
            array_map(fn (PermissionName $permission) => $permission->value, self::ROLE_PERMISSIONS),
        );

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    public function down(): void
    {
        Role::query()->where('name', self::ROLE)->where('guard_name', 'web')->forceDelete();

        Permission::query()
            ->whereIn('name', array_map(fn (PermissionName $permission) => $permission->value, self::NEW_PERMISSIONS))
            ->where('guard_name', 'web')
            ->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
