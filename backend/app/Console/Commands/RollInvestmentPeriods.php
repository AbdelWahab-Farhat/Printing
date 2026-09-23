<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Exceptions\PeriodHasOrdersInFlight;
use App\Domain\Investor\Models\InvestmentPeriod;
use Illuminate\Console\Command;

/**
 * يُدوّر الفترات بنفسه: يُقفل المستحقّة ويفتح التالية، فلا ينتظر الصندوقُ ضغطةَ زرّ.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — البند ٧ والشريحة ٠.٤.
 * المالكُ اختار الإغلاق الآليّ، وهذا هو؛ والزرّان في الواجهة يبقيان **احتياطاً** لا طريقاً
 * أساسياً — يستدعيان الفعلين نفسَهما، فلا يوجد سلوكان للإقفال يختلفان.
 *
 * ## إقفالٌ ثم فتحٌ في نداءٍ واحد
 *
 * الترتيبُ ليس تفصيلاً: `OpenInvestmentPeriod` يرفض فتحَ ثانيةٍ ما دامت واحدةٌ مفتوحة، وتاريخُ
 * بدايتها هو الغدُ التالي لنهاية سابقتها. فلو فُتحت قبل الإقفال لما فُتحت أصلاً، ولو أُقفلت ولم
 * تُفتح تاليتُها لبقي الصندوق بلا فترةٍ تستقبل قيوده — وطلبيةُ الغد لا تجد أين تقع.
 *
 * ## وما يمنع الإقفال يُترَك لغدٍ، لا يُتجاوَز
 *
 * طلبيةٌ لم تُسلَّم بعد تحبس الفترة بحقّ: ربحُها يخصّ فترةَ تاريخها، فإقفالُها قبل وصولها يجمّد
 * رقماً ناقصاً. والمهمّةُ **لا تمرّ بـ`$overrideReason` أبداً** — التجاوزُ قرارٌ يُكتب باسم من
 * اتّخذه، ومهمّةُ منتصف ليلٍ ليست أحداً. فتنصرف المهمّةُ وتعود غداً، وتقفل من تلقاء نفسها يومَ
 * تصل آخرُ طلبية. أما الطلبيةُ العالقة التي لا تصل ولا تُلغى فتبقى للمالك وزرِّه ولوحتِه
 * التي تقول «مستحقّةُ الإقفال منذ كذا يوماً».
 *
 * ## ولماذا الإعادةُ آمنة
 *
 * الفعلان يقرآن الحالةَ من القاعدة داخل معاملةٍ بـ`lockForUpdate`، والفهرسُ الفريد يمنع فترتين
 * مفتوحتين مهما كان الطريق. فنداءان في دقيقةٍ واحدة — أو `schedule:run` يُنصَّب مرّتين — لا
 * يكتبان مرّتين. ولذلك تُشغَّل هذه يومياً بلا حساسيةٍ لساعةٍ بعينها.
 *
 * **وبلا `cron` لا تعمل هذه ولا غيرها**؛ `deploy.sh` لا ينصبه. السطرُ على كل خادم:
 *
 *     * * * * * cd /path/to/backend && php artisan schedule:run >> /dev/null 2>&1
 */
class RollInvestmentPeriods extends Command
{
    protected $signature = 'investment:roll-periods
                            {--dry-run : يقول ما كان سيفعله ولا يكتب شيئاً}';

    protected $description = 'يُقفل الفترةَ المستحقّة ويفتح التالية';

    public function __construct(
        private readonly OpenInvestmentPeriod $openPeriod,
        private readonly CloseInvestmentPeriod $closePeriod,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $dryRun = (bool) $this->option('dry-run');

        $open = InvestmentPeriod::open();

        if ($open !== null && ! $open->isDueToClose(now())) {
            $this->info("الفترة «{$open->code}» جارية إلى {$open->ends_on->toDateString()} — لا شيء اليوم.");

            return self::SUCCESS;
        }

        if ($open !== null) {
            $late = (int) $open->ends_on->endOfDay()->diffInDays(now());

            if ($dryRun) {
                $this->info("كانت ستُقفَل الفترة «{$open->code}» (مستحقّة منذ {$late} يوماً) وتُفتح التالية.");

                return self::SUCCESS;
            }

            try {
                // بلا سببِ تجاوز: ما يحبسها بحقٍّ يبقى حابساً، والمهمّةُ تعود غداً.
                $closed = ($this->closePeriod)(null);
            } catch (PeriodHasOrdersInFlight $e) {
                $this->warn("الفترة «{$open->code}» مستحقّةُ الإقفال منذ {$late} يوماً ولم تُقفَل: {$e->getMessage()}");

                return self::SUCCESS;
            }

            $this->info("أُقفلت الفترة «{$closed->code}» — صافي الربح {$closed->net_profit}.");
        }

        if ($dryRun) {
            $this->info('وكانت ستُفتح فترةٌ جديدة.');

            return self::SUCCESS;
        }

        $period = ($this->openPeriod)(null);

        $this->info(
            "فُتحت الفترة «{$period->code}»: "
            ."{$period->starts_on->toDateString()} — {$period->ends_on->toDateString()}، "
            ."بابُ الاكتتاب إلى {$period->subscription_closes_on->toDateString()}."
        );

        return self::SUCCESS;
    }
}
