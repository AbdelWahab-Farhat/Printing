<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\FoldDealIntoFund;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Console\Command;

/**
 * يُدخل صفقةً قديمة إلى الصندوق — §٠.٩ من المواصفة، والفعلُ كلُّه في {@see FoldDealIntoFund}.
 *
 * يُشغَّل مرّةً على الإنتاج يومَ يُفتح فيه الصندوق، و`--dry-run` أولاً: الأرقامُ تُحسب يومَها من
 * الدفاتر، فما في المواصفة أرقامُ نسخة التجربة لا أرقامُ اليوم.
 *
 * **وباسم إنسان** (`--by`): حركتا المخزن تطلبان يداً، والتحويلُ قرارٌ يُكتب باسم من اتّخذه.
 */
class FoldDealIntoFundCommand extends Command
{
    protected $signature = 'investment:fold-deal
                            {deal : رمز الصفقة القديمة، مثل D1}
                            {--by= : هاتف المستخدم الذي يُكتب التحويلُ باسمه، أو رقمُه}
                            {--dry-run : يعرض الأرقام ولا يكتب شيئاً}';

    protected $description = 'يُدخل صفقةً قديمة إلى الصندوق: بضاعتُها ورأسُ مالها وحداتٌ في الفترة المفتوحة';

    public function handle(FoldDealIntoFund $fold): int
    {
        $deal = InvestorDeal::query()->where('code', (string) $this->argument('deal'))->first();

        if ($deal === null) {
            $this->error("لا صفقةَ بالرمز {$this->argument('deal')}.");

            return self::FAILURE;
        }

        if ((bool) $this->option('dry-run')) {
            $this->report($fold->preview($deal), 'لو حُوِّلت الآن');

            return self::SUCCESS;
        }

        $actor = $this->actor();

        if ($actor === null) {
            $this->error('يُكتب التحويلُ باسم إنسان: --by=<هاتف المستخدم أو رقمه>.');

            return self::FAILURE;
        }

        $this->report($fold($deal, (int) $actor->getKey()), 'حُوِّلت');

        return self::SUCCESS;
    }

    private function actor(): ?User
    {
        $by = trim((string) $this->option('by'));

        if ($by === '') {
            return null;
        }

        return User::query()->where('phone', $by)->first()
            ?? (ctype_digit($by) ? User::query()->find((int) $by) : null);
    }

    /** @param array<string, mixed> $plan */
    private function report(array $plan, string $heading): void
    {
        $this->info("الصفقة {$plan['deal']} — {$heading}:");
        $this->line("  على الرفّ: {$plan['shelf_quantity']} بتكلفة {$plan['shelf_cost']} — منها حصةُ الشركة {$plan['company_share_of_shelf']}");
        $this->line("  في الطريق: {$plan['in_flight_cost']} بالتكلفة — تبقى في الصفقة حتى تصل");
        $this->line("  سعرُ الوحدة: {$plan['unit_price']}");

        foreach ($plan['investors'] as $line) {
            $this->line("  {$line['name']}: رأسُ ماله {$line['capital']} — يبقى {$line['stays']}، يدخل {$line['enters']}"
                ." (بضاعة {$line['goods']} + نقد {$line['cash']}) = {$line['units']} وحدة، وربحٌ إلى محفظته {$line['profit']}");
        }
    }
}
