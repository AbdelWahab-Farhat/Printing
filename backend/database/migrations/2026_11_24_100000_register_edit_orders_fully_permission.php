<?php

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * Registers `orders.edit_fully` and grants it to nobody.
 *
 * An administrator already has it through `Gate::before`; any other role is given it on the
 * roles screen. See PermissionName::EditOrdersFully.
 */
return new class extends Migration
{
    public function up(): void
    {
        Permission::findOrCreate(PermissionName::EditOrdersFully->value, 'web');

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    public function down(): void
    {
        Permission::query()
            ->where('name', PermissionName::EditOrdersFully->value)
            ->where('guard_name', 'web')
            ->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
