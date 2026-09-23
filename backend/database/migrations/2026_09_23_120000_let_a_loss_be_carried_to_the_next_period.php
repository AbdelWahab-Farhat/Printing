<?php

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Enums\WalletEntryType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * خسارةٌ وصلت بعد أن خرج المال — تُرحَّل ولا تُشطب ولا تتبخّر.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §٠.٨، §١٢ب.
 *
 * ## الحالُ التي وُجد لها هذان النوعان
 *
 * سبتمبر أُقفل في موعده وخرجت أرباحُه إلى الجيوب، ثم تُسلَّم آخرُ طلبياته في أكتوبر **بخسارة**.
 * والمالُ راح: لا `capital_writedown` — قرارُ المالك أن رأس المال لا يُمسّ هنا — ولا تتحمّله
 * الشركة: **«خليه بسالب مش مهم، يُضاف إنقاصاً لربحه حتى ولو أصبحت سالبة، ولا نتحمّله»**، ثم
 * أكّدها: «الرصيد السالب يظل مطالبة على المستثمر نفسه، ويُرحّل حتى يُخصم من أرباحه المستقبلية».
 *
 * **ولو وقف السالبُ مكانه لتبخّرت الخسارة**: الفترةُ تُقفَل ولا يُقرأ رصيدُها ثانيةً، فلا هو
 * تحمّلها ولا الشركة. فالترحيلُ ليس تفصيلاً في التنفيذ، هو الفرقُ بين «لا نتحمّله» وبين لا أحد.
 *
 * ## ولماذا نوعان لا واحد
 *
 * الترحيلُ **حركةٌ بين فترتين**، ولكلِّ فترةٍ أرقامُها. فيُكتب صفّان يتعادلان في الدفتر كلِّه:
 *
 * ```
 * loss_carried_out  (+1 على profit_deal)  في الفترة المنتهية  →  يسدّ حفرتَها فتُقفَل على صفر
 * loss_carried_in   (−1 على profit_deal)  في الفترة المفتوحة  →  تستنزله من أوّل ربحٍ يُفرَج عنه
 * ```
 *
 * ونوعٌ واحدٌ يُقرأ مرّتين كان سيعني صفّاً يخصّ فترتين — وكلُّ صفٍّ هنا مختومٌ بفترةٍ واحدة،
 * وعليه يقوم كلُّ رقمٍ في الميزة.
 *
 * ## وهما صفّا تسويةٍ لا صفّا ربح
 *
 * لا طريقةَ دفعٍ لهما ولا مصدرَ: لا دينارَ عبر الطاولة، ولا طلبيةَ وراءهما — بل قرارُ إقفال.
 * فذراعُهما في `_shape` هي ذراعُ `profit_release` و`capital_writedown`، لا ذراعُ `profit`.
 *
 * @see WalletEntryType::LossCarriedOut
 * @see CloseInvestmentPeriod
 */
return new class extends Migration
{
    private const ARM = "'allocation', 'release', 'profit_release',\n                             'capital_writedown', 'loss_absorbed_by_company'";

    public function up(): void
    {
        $this->shapeWith(self::ARM.", 'loss_carried_out', 'loss_carried_in'");
    }

    public function down(): void
    {
        // **ولا صفَّ ترحيلٍ ينجو من الرجوع.** الشرطُ السابق لا يعرف النوعين، فصفٌّ يحملهما يمنع
        // إضافتَه. وحذفُهما حذفٌ ناعم: الدفترُ لا يُمحى منه شيءٌ، والزوجُ يتعادل فلا يترك أثراً
        // في رصيدٍ بعد رفعه.
        DB::table('investor_wallet_entries')
            ->whereIn('type', ['loss_carried_out', 'loss_carried_in'])
            ->whereNull('deleted_at')
            ->update(['deleted_at' => now()]);

        $this->shapeWith(self::ARM);
    }

    private function shapeWith(string $settlementTypes): void
    {
        DB::statement('ALTER TABLE investor_wallet_entries DROP CONSTRAINT investor_wallet_entries_shape');

        DB::statement(<<<SQL
            ALTER TABLE investor_wallet_entries
            ADD CONSTRAINT investor_wallet_entries_shape CHECK (
                (type IN ('deposit', 'withdrawal', 'profit_withdrawal')
                    AND investor_deal_id IS NULL AND method IS NOT NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type = 'profit_capitalisation'
                    AND investor_deal_id IS NULL AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ({$settlementTypes})
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
