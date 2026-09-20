<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * البابُ الأول في تحويل الصفقات إلى صندوقٍ مستمرّ: مالٌ لا يسمّي صفقة.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة صفر.
 *
 * **تغييران، وهما في ترحيلٍ واحد عن قصد**، لأن الأول وحده يفتح ثغرةً لا يسدّها إلا الثاني، وبينهما
 * — لو شُحنا متفرّقَين — نافذةٌ تُدفع فيها الطلبيةُ مرّتين بلا أثر.
 *
 * ## الأول: `_shape` يقبل الصندوق
 *
 * القيدُ القائم يشترط `investor_deal_id IS NOT NULL` على كل نوعٍ يخصّ صفقة — وهو صحيحٌ تماماً
 * في نظامٍ كلُّ مالٍ فيه يخصّ صفقة. وفي الصندوق المستمرّ لا صفقةَ يسمّيها المال: رأسُ المال يدخل
 * الصندوق، وربحُ الطلبية يخصّ الصندوق، والفترة هي التي تُغلق لا الصفقة.
 *
 * فيُرفع الشرطُ عن ذراعَي «الصفقة» و«الطلبية» **ولا يُستبدَل بنقيضه**: الشكلان قائمان معاً خلال
 * الانتقال — صفوفُ الصفقات التاريخية تسمّي صفقتها، وصفوفُ الصندوق لا تسمّي شيئاً، والقيدُ يقبلهما.
 * وتُترك ذراعُ المحفظة (`deposit`/`withdrawal`/`profit_withdrawal`) على `IS NULL` كما هي، لأنها
 * لم تكن يوماً تخصّ صفقة.
 *
 * ## الثاني: الفهرسُ الذي كان سيموت صامتاً
 *
 * `investor_wallet_entries_one_earning_per_source` هو ما يمنع مستمعاً يعمل مرّتين من أن يدفع
 * الطلبيةَ مرّتين. ومفتاحُه يحمل `investor_deal_id` — **و Postgres لا يرى `NULL` مساوياً لـ
 * `NULL` في فهرسٍ فريد**. فأولُ صفٍّ للصندوق كان سيُسقط الحمايةَ كلَّها بلا خطأٍ ولا شاشة: صفّان
 * بـ٧٥٠ لكلٍّ منهما يُقبلان، فيُدفع ١٬٥٠٠ عن ربحٍ قدرُه ٧٥٠، ولا يظهر الفرق في أيّ مكان لأن كل
 * رصيدٍ في هذه الميزة مشتقٌّ من الصفوف لا محفوظٌ في عمود.
 *
 * والعلاجُ فهرسٌ ثانٍ لا تعديلُ الأول: الأولُ يحرس تاريخَ الصفقات كما حرسه دائماً، والثاني يحرس
 * الصندوق. **ووضعُ `investment_period_id` مكان الصفقة في المفتاح خطأٌ مقابل** — يسمح للطلبية
 * الواحدة أن تُدفع مرّةً في كل فترة؛ الطلبيةُ تُدفع مرّةً واحدة في عمر الصندوق كلِّه.
 *
 * **ولا يفشل هذا الترحيل على قاعدةٍ حيّة:** القيدُ القائم كان يمنع أصلاً وجودَ صفٍّ يحمل
 * `source_type` بلا صفقة، فلا صفَّ واحداً يقع تحت شرطِ الفهرس الجديد يوم إنشائه.
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

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investor_wallet_entries_one_fund_earning_per_source
            ON investor_wallet_entries (investor_id, source_type, source_id, source_sequence)
            WHERE investor_deal_id IS NULL AND source_type IS NOT NULL AND deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS investor_wallet_entries_one_fund_earning_per_source');

        DB::statement('ALTER TABLE investor_wallet_entries DROP CONSTRAINT investor_wallet_entries_shape');

        DB::statement(<<<'SQL'
            ALTER TABLE investor_wallet_entries
            ADD CONSTRAINT investor_wallet_entries_shape CHECK (
                (type IN ('deposit', 'withdrawal', 'profit_withdrawal')
                    AND investor_deal_id IS NULL AND method IS NOT NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('allocation', 'release', 'profit_release',
                             'capital_writedown', 'loss_absorbed_by_company')
                    AND investor_deal_id IS NOT NULL AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('profit', 'loss')
                    AND investor_deal_id IS NOT NULL AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NOT NULL AND source_id IS NOT NULL)
                OR (type = 'reversal'
                    AND method IS NULL AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }
};
