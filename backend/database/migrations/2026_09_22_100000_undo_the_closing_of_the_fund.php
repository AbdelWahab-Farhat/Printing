<?php

declare(strict_types=1);

use App\Domain\Investor\Actions\WithdrawFromFund;
use App\Domain\Investor\Exceptions\TheFundIsNotADeal;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * صندوقٌ أُغلق بالخطأ: يُفتح، وتُعكَس صفوفُ التسوية التي كتبها إقفالُه.
 *
 * وقع هذا على سيرفر التجربة في ٢٢ سبتمبر ٢٠٢٦ الساعة ١٢:٤٣ — كان صفُّ `FUND` يظهر في شاشة
 * الصفقات، وفي صفحته زرُّ إغلاق. فأعاد `CloseInvestorDeal` رأسَ مال ثلاثة مستثمرين (١٧٬٠٠٠)
 * إلى محافظهم بثلاثة صفوف `release`، **وبقيت وحداتُهم قائمة** — نصيبٌ في صندوقٍ لم يعد مالُهم
 * فيه — ثم صار كلُّ اشتراكٍ جديد يُرفض بـ«الصفقة FUND «مغلقة» ولا تقبل حركات مالية جديدة».
 * الحارسُ الذي يمنع تكرارَه هو {@see TheFundIsNotADeal}؛ وهذا
 * يصلح ما وقع قبله.
 *
 * ## يُعكَس ولا يُحذَف
 *
 * «المالُ دفترٌ يُضاف إليه ولا يُمحى منه». فالصفوفُ تبقى وتُكتب أمامها صفوفُ `reversal` تحمل
 * مبالغها — و`InvestorWalletEntry::deltas()` تنفي أثرَ الصفّ المعكوس وحده، فلا رقمَ يُصحَّح
 * هنا بيد.
 *
 * ## ولماذا النافذةُ الزمنية
 *
 * `release` على الصندوق **ليس دائماً خطأ**: هو أيضاً بابُ الاسترداد
 * ({@see WithdrawFromFund}) — مستثمرٌ يخرج ماله من الصندوق إلى
 * محفظته. فلا تُؤخذ أنواعُ التسوية كلُّها، بل ما كُتب منها في اللحظة التي خُتم فيها
 * `closed_at` وحدها. ثانيتان من الفسحة لأن الإقفالَ يكتب صفوفَه ثم يختم، والكتابتان قد
 * تقعان على طرفَي ثانية.
 *
 * أمامي فقط، كعادة الملف: صندوقٌ مفتوحٌ على أيّ قاعدةٍ أخرى — أو لا صندوقَ فيها — لا يمسّه هذا.
 */
return new class extends Migration
{
    /** ما يكتبه `CloseInvestorDeal::settle()` وحده. */
    private const SETTLEMENT_TYPES = [
        'release',
        'profit_release',
        'capital_writedown',
        'loss_absorbed_by_company',
    ];

    public function up(): void
    {
        $fund = DB::table('investor_deals')
            ->where('code', 'FUND')
            ->where('status', 'closed')
            ->first(['id', 'closed_at']);

        if ($fund === null) {
            return;
        }

        DB::transaction(function () use ($fund): void {
            $types = implode(',', array_map(fn (string $t) => "'".$t."'", self::SETTLEMENT_TYPES));

            DB::insert(<<<SQL
                INSERT INTO investor_wallet_entries (
                    investor_id, investor_deal_id, investment_period_id, type, amount,
                    reverses_entry_id, occurred_at, notes, created_at, updated_at
                )
                SELECT
                    e.investor_id, e.investor_deal_id, e.investment_period_id, 'reversal', e.amount,
                    e.id, NOW(), ?, NOW(), NOW()
                FROM investor_wallet_entries e
                WHERE e.investor_deal_id = ?
                  AND e.type IN ({$types})
                  AND e.deleted_at IS NULL
                  AND e.occurred_at BETWEEN (? ::timestamp - INTERVAL '2 seconds') AND ? ::timestamp
                  AND NOT EXISTS (
                      SELECT 1 FROM investor_wallet_entries r
                      WHERE r.reverses_entry_id = e.id AND r.deleted_at IS NULL
                  )
            SQL, [
                'إبطال إقفال الصندوق — أُغلق بالخطأ',
                $fund->id,
                $fund->closed_at,
                $fund->closed_at,
            ]);

            DB::table('investor_deals')->where('id', $fund->id)->update([
                'status' => 'open',
                'closed_at' => null,
                'updated_at' => now(),
            ]);
        });
    }

    public function down(): void {}
};
