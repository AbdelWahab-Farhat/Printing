<?php

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * `orders.payments.review` and `orders.payments.keep_excess`, so the roles screen can tick them on
 * a database that already exists. Nobody holds them yet: administrators reach everything through
 * `Gate::before`, and the owner hands them out.
 */
return new class extends Migration
{
    /**
     * @return list<PermissionName>
     */
    private function permissions(): array
    {
        return [
            PermissionName::ReviewOrderPayments,
            PermissionName::KeepOrderExcess,
        ];
    }

    public function up(): void
    {
        foreach ($this->permissions() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    public function down(): void
    {
        Permission::query()
            ->whereIn('name', array_map(fn (PermissionName $p) => $p->value, $this->permissions()))
            ->where('guard_name', 'web')
            ->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
