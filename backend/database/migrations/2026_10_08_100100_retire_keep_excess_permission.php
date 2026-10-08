<?php

use Illuminate\Database\Migrations\Migration;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * `orders.payments.keep_excess` يخرج — الزائدُ إيرادٌ ساعةَ الدفعة، فلا زرَّ يقرّره ولا صلاحية.
 *
 * قرارُ صاحب العمل ٢٠٢٦-١٠-٠٧: «ديمة اعتبره إيراد، لا حاجة لزر الإيراد». الصلاحيةُ سجّلها ترحيلُ
 * `2026_10_04_100100`، ولم تعد شيئاً يُفحص، فتُحذف من الكتالوج — ومن كل دورٍ أُعطيها، بقيد
 * `role_has_permissions` المتسلسل — كي لا تبقى خانةٌ في شاشة الأدوار لا تفتح شيئاً.
 *
 * See Docs/payments/PAYMENT-REVIEW-AND-OVERPAY.md.
 */
return new class extends Migration
{
    private const RETIRED = 'orders.payments.keep_excess';

    public function up(): void
    {
        Permission::query()->where('name', self::RETIRED)->where('guard_name', 'web')->delete();

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    /**
     * تعود الصلاحيةُ إلى الكتالوج بلا أحدٍ يحملها: مَن أُعطيها قبلُ قرارٌ لا يُستعاد من هنا.
     */
    public function down(): void
    {
        Permission::findOrCreate(self::RETIRED, 'web');

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
};
