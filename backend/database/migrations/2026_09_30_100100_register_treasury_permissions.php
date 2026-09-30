<?php

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * The treasury's grants and the vendor-payment trio, so the roles screen can tick them on a
 * database that already exists. Nobody holds them yet: administrators reach everything through
 * `Gate::before`, and the owner hands the rest out.
 */
return new class extends Migration
{
    /**
     * @return list<PermissionName>
     */
    private function permissions(): array
    {
        return [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::AdjustTreasuryBalances,
            PermissionName::ReverseTreasuryOperations,
            PermissionName::ManageTreasury,
            PermissionName::ViewVendorPayments,
            PermissionName::RecordVendorPayments,
            PermissionName::ReverseVendorPayments,
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
