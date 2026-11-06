<?php

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * «محافظ الموظفين» — الصلاحيات الست، لتظهر في شاشة الأدوار على قاعدةٍ قائمة. لا يملكها أحدٌ بعد:
 * المدير يصل إلى كل شيء عبر `Gate::before`، وصاحب العمل يمنحها بقرار.
 */
return new class extends Migration
{
    private const PERMISSIONS = [
        PermissionName::ViewEmployeeWallets,
        PermissionName::DepositToEmployeeWallets,
        PermissionName::CreditEmployeeWallets,
        PermissionName::WithdrawFromEmployeeWallets,
        PermissionName::AdjustEmployeeWallets,
        PermissionName::ReverseEmployeeWalletEntries,
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
