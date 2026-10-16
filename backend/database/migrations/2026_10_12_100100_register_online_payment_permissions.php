<?php

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * «الدفع الإلكتروني» — the three grants, so the roles screen can tick them. Nobody holds them yet:
 * administrators reach everything through `Gate::before`.
 */
return new class extends Migration
{
    private const PERMISSIONS = [
        PermissionName::ViewOnlinePayments,
        PermissionName::ReconcileOnlinePayments,
        PermissionName::ManageOnlinePaymentMethods,
    ];

    public function up(): void
    {
        foreach (self::PERMISSIONS as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    public function down(): void
    {
        Permission::query()
            ->whereIn('name', array_map(fn (PermissionName $p) => $p->value, self::PERMISSIONS))
            ->where('guard_name', 'web')
            ->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
