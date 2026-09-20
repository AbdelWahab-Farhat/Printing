<?php

use App\Domain\Investor\Enums\WalletEntryType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * الربحُ يصير رأسَ مالٍ بصفٍّ واحد — «يمكنه تحويل رصيد الأرباح إلى رأس المال ليقوم بإستعماله».
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * ## لماذا صفٌّ واحد لا صفّان
 *
 * البديلُ الظاهر — «سحبُ أرباح» ثم «إيداعُ رأس مال» — يكذب مرّتين: يقول إن مالاً خرج من الدرج
 * ومالاً دخله ولم يتحرّك دينار، ويكتب في الخزينة صرفاً وقبضاً لم يقعا. وصفٌّ واحد يحرّك جيبين
 * معاً هو ما بُني له {@see WalletEntryType::deltas()} أصلاً — ثلاثةُ
 * أنواعٍ قبله تفعلها.
 *
 * ## وشكلُه ذراعٌ خامس في القيد
 *
 * ذراعُ المحفظة القائمة تشترط `method IS NOT NULL` لأن أنواعها الثلاثة مالٌ يعبر الطاولة. وهذا
 * لا يعبرها: لا نقدَ يُسلَّم ولا طريقةَ دفعٍ تُسمّى. فذراعٌ خاصّةٌ به، بلا صفقةٍ وبلا طريقةٍ وبلا
 * مصدر — والقيدُ يظلّ يمنع أن يُكتب بأيّ شكلٍ آخر.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE investor_wallet_entries DROP CONSTRAINT investor_wallet_entries_shape');

        DB::statement(<<<'SQL'
            ALTER TABLE investor_wallet_entries
            ADD CONSTRAINT investor_wallet_entries_shape CHECK (
                (type IN ('deposit', 'withdrawal', 'profit_withdrawal')
                    AND investor_deal_id IS NULL AND method IS NOT NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type = 'profit_capitalisation'
                    AND investor_deal_id IS NULL AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('allocation', 'release', 'profit_release',
                             'capital_writedown', 'loss_absorbed_by_company')
                    AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('profit', 'loss')
                    AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NOT NULL AND source_id IS NOT NULL)
                OR (type = 'reversal'
                    AND method IS NULL AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE investor_wallet_entries DROP CONSTRAINT investor_wallet_entries_shape');

        DB::statement(<<<'SQL'
            ALTER TABLE investor_wallet_entries
            ADD CONSTRAINT investor_wallet_entries_shape CHECK (
                (type IN ('deposit', 'withdrawal', 'profit_withdrawal')
                    AND investor_deal_id IS NULL AND method IS NOT NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('allocation', 'release', 'profit_release',
                             'capital_writedown', 'loss_absorbed_by_company')
                    AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('profit', 'loss')
                    AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NOT NULL AND source_id IS NOT NULL)
                OR (type = 'reversal'
                    AND method IS NULL AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }
};
