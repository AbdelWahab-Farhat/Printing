<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\NoPeriodIsOpen;
use App\Domain\Investor\Exceptions\SubscriptionWindowIsClosed;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * ربحُه المتاح للسحب يعود إلى الصندوق — «تحويل أرباح إلى رأس مال» ثم «اشتراك في الصندوق»
 * بالمبلغ نفسه، في معاملةٍ واحدة.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §١٤.
 *
 * **خطوتان قائمتان لا بابٌ جديد.** الأولى {@see RecordWalletEntry} بـ`profit_capitalisation` تُخرج
 * الربحَ من نقد الصندوق، والثانية {@see DepositToFund} تُعيده بوحداتٍ بسعر اليوم وحبسِها. فنقدُ
 * الصندوق لا يتحرّك صافياً، وكلُّ حارسٍ في الطريق اليدويّ يحرس هذا كذلك: سقفُ الربح، والنافذة،
 * والفترةُ المفتوحة، والحبس.
 *
 * **وإمّا أن تقعا معاً أو لا يقع منهما شيء.** ربحٌ صار رأسَ مالٍ ولم يُكتتب به رجلٌ يظنّ مالَه
 * يعمل وهو ينتظر في محفظته — فإن رفضت النافذةُ الثانيةَ رجعت الأولى معها.
 */
final class ReinvestProfit
{
    public const NOTE = 'إعادة استثمار تلقائي';

    public function __construct(
        private readonly InvestorBalances $balances,
        private readonly RecordWalletEntry $wallet,
        private readonly DepositToFund $deposit,
    ) {}

    /**
     * null حين لا ربحَ متاحاً يُعاد.
     *
     * @return array{capitalisation: InvestorWalletEntry, wallet_entry: InvestorWalletEntry, units: InvestmentUnit}|null
     *
     * @throws NoPeriodIsOpen
     * @throws SubscriptionWindowIsClosed
     */
    public function __invoke(int $investorId, ?int $actorId): ?array
    {
        return DB::transaction(function () use ($investorId, $actorId): ?array {
            // **المبلغُ يُقرأ تحت القفل.** سحبُ أرباحٍ يدويّ في اللحظة نفسها كان سيقرأ الرصيدَ نفسه،
            // فيمرّ الاثنان ويُعاد ما سُحب.
            Investor::query()->whereKey($investorId)->lockForUpdate()->firstOrFail();

            $amount = Money::round($this->balances->forInvestor($investorId)['wallet']['profit']);

            if (! Money::isPositive($amount)) {
                return null;
            }

            $capitalisation = ($this->wallet)(
                new WalletEntryData(
                    investorId: $investorId,
                    type: WalletEntryType::ProfitCapitalisation,
                    amount: $amount,
                    occurredAt: now()->toImmutable(),
                    notes: self::NOTE,
                ),
                $actorId,
            );

            $subscription = ($this->deposit)($investorId, $amount, $actorId, self::NOTE);

            return ['capitalisation' => $capitalisation, ...$subscription];
        });
    }
}
