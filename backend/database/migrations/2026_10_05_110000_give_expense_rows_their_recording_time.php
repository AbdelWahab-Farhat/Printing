<?php

use App\Domain\Investor\Models\InvestorDealExpense;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * حركاتُ المصروف القائمة تأخذ ساعةَ تسجيلها — يومُها كما هو.
 *
 * كانت تُكتب منتصفَ ليل UTC من اليوم المختار (النموذجُ يرسل يوماً بلا ساعة)، فتظهر الثانيةَ صباحاً
 * وتُرتَّب تحت كلِّ ما سُجِّل يومَها قبلها. والساعةُ الحقيقية محفوظةٌ في `created_at` المصروف، فتُركَّب
 * على يومه بتوقيت ليبيا — القاعدةُ نفسُها التي تكتب بها {@see InvestorDealExpense::momentFor()} من الآن.
 *
 * تُمسّ الصفوفُ التي ساعتُها منتصفُ الليل تماماً وحدها: صفوفُ المصروف في خزينة الصندوق (والمصروفُ
 * ونصيبُ الشركة منه)، وحركاتُه في الخزائن. والعكوسُ كُتبت بساعتها أصلاً. ولا رجوعَ عنه: إصلاحُ ساعة
 * لا يُعاد خطؤه.
 */
return new class extends Migration
{
    public function up(): void
    {
        $zone = (string) config('app.business_timezone', 'Africa/Tripoli');

        // يومُ المصروف + ساعةُ تسجيله المحلية، ثم إلى UTC — كما يُخزَّن كلُّ وقتٍ في هذه القاعدة.
        $moment = "((e.incurred_on + ((e.created_at AT TIME ZONE 'UTC') AT TIME ZONE ?)::time) AT TIME ZONE ?) AT TIME ZONE 'UTC'";

        DB::statement(<<<SQL
            UPDATE investment_cash_entries c
            SET occurred_at = {$moment}
            FROM investor_deal_expenses e
            WHERE c.source_type = 'investor_deal_expense'
              AND c.source_id = e.id
              AND c.type IN ('expense', 'expense_covered_by_company')
              AND c.occurred_at::time = '00:00:00'
              AND e.created_at IS NOT NULL
        SQL, [$zone, $zone]);

        DB::statement(<<<SQL
            UPDATE treasury_movements m
            SET occurred_at = {$moment}
            FROM investor_deal_expenses e
            WHERE m.source_type = 'investor_deal_expense'
              AND m.source_id = e.id
              AND m.occurred_at::time = '00:00:00'
              AND e.created_at IS NOT NULL
        SQL, [$zone, $zone]);
    }

    public function down(): void
    {
        // لا شيء: الساعةُ الصحيحة لا تُعاد إلى منتصف الليل.
    }
};
