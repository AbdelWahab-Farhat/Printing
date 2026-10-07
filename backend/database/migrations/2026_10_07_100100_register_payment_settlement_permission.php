<?php

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * `orders.payments.settle`, so the roles screen can tick it on a database that already exists.
 * Nobody holds it yet: administrators reach everything through `Gate::before`, and the owner
 * hands it out.
 */
return new class extends Migration
{
    public function up(): void
    {
        Permission::findOrCreate(PermissionName::SettleOrderPayments->value, 'web');

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    public function down(): void
    {
        Permission::query()
            ->where('name', PermissionName::SettleOrderPayments->value)
            ->where('guard_name', 'web')
            ->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
