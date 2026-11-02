<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Investor\Actions\ReinvestProfit;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * يُعيد إلى الصندوق ربحَ كلِّ مستثمرٍ زرُّه مُشغَّل — §١٤.
 *
 * **كنسٌ لا كتابةٌ عند الإفراج**، لأن الإفراجَ يقع حيث لا يُقبل اشتراك: `roll-periods` يُقفل قبل أن
 * يفتح، والطلبيةُ المتأخّرة تُفرج عن ربحها خارج النافذة. فيمرّ هذا كلَّ ساعةٍ بعده، ولا يفعل شيئاً
 * إلا والنافذةُ مفتوحة اليوم؛ وما يُفرَج عنه خارجها يبقى ربحاً قابلاً للسحب حتى التالية.
 *
 * **وإعادتُه لا تكتب شيئاً مرّتين**: بعد الإعادة صار المتاحُ صفراً. ومستثمرٌ يرفضه حارسٌ لا يوقف
 * الباقين — يُسجَّل ويُتخطّى، والكنسةُ التالية تحاوله ثانيةً.
 */
class ReinvestProfitCommand extends Command
{
    protected $signature = 'investment:reinvest-profit
                            {--dry-run : يقول من سيُعاد ربحُه ولا يكتب شيئاً}';

    protected $description = 'يُعيد استثمار الأرباح المتاحة لكلّ مستثمرٍ فعّل «إعادة استثمار الأرباح تلقائياً» ما دامت نافذة الاكتتاب مفتوحة';

    public function handle(ReinvestProfit $reinvest): int
    {
        $period = InvestmentPeriod::open();

        if ($period === null || ! $period->acceptsCapitalOn(now())) {
            $this->info('نافذة الاكتتاب مغلقة — لا شيء يُعاد الآن.');

            return self::SUCCESS;
        }

        $investors = Investor::query()
            ->where('is_active', true)
            ->where('auto_reinvest_profit', true)
            ->orderBy('id')
            ->get();

        if ((bool) $this->option('dry-run')) {
            foreach ($investors as $investor) {
                $this->info("{$investor->code} {$investor->name} — زرُّه مُشغَّل.");
            }

            return self::SUCCESS;
        }

        $failed = 0;

        foreach ($investors as $investor) {
            try {
                $result = $reinvest((int) $investor->getKey(), null);
            } catch (Throwable $e) {
                $failed++;
                Log::warning('investment:reinvest-profit skipped an investor', [
                    'investor_id' => $investor->getKey(),
                    'error' => $e->getMessage(),
                ]);
                $this->warn("{$investor->code}: {$e->getMessage()}");

                continue;
            }

            if ($result !== null) {
                $this->info("{$investor->code} {$investor->name} — أُعيد {$result['capitalisation']->amount} د.ل إلى الصندوق.");
            }
        }

        return $failed === 0 ? self::SUCCESS : self::FAILURE;
    }
}
