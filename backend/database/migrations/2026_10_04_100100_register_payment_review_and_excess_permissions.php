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
     * نصًّا لا حالةً من {@see PermissionName}: `orders.payments.keep_excess` خرج من الكتالوج يوم
     * صار الزائدُ إيراداً بلا زرّ (٢٠٢٦-١٠-٠٧)، وهذا الترحيلُ يجب أن يجري كما جرى على كل قاعدة —
     * والترحيلُ اللاحق `2026_10_08_100000` يُخرجها. ما يفعله لم يتغيّر حرفاً.
     *
     * @return list<string>
     */
    private function permissions(): array
    {
        return [
            PermissionName::ReviewOrderPayments->value,
            'orders.payments.keep_excess',
        ];
    }

    public function up(): void
    {
        foreach ($this->permissions() as $permission) {
            Permission::findOrCreate($permission, 'web');
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    public function down(): void
    {
        Permission::query()
            ->whereIn('name', $this->permissions())
            ->where('guard_name', 'web')
            ->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
