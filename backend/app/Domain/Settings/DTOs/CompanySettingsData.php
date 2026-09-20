<?php

declare(strict_types=1);

namespace App\Domain\Settings\DTOs;

/**
 * Every company-wide default, in one object.
 *
 * All of them together rather than a method per setting: they are edited on one screen, saved by one
 * button, and audited as one change. A partial update would make «من غيّر مدة الإقفال؟» a question
 * the trail answers with four separate rows that happened to share a second.
 */
final readonly class CompanySettingsData
{
    public function __construct(
        /** The investors' share of a pool's period profit, as a decimal string. */
        public string $investorProfitSharePercent,
        /** How long a profit period runs — «كل شهر», «كل شهرين». */
        public int $profitPeriodMonths,
        /** How often the comprehensive review happens, in months. */
        public int $settlementPeriodMonths,
        /**
         * How many days after a period opens that capital may still join **that** period.
         *
         * Zero makes the boundary strict. See INVESTMENT-FUND-DESIGN.md §5 for why this window is
         * what lets ownership stay a plain capital ratio.
         */
        public int $entryGraceDays,
        /**
         * How many months an investor's capital must stay in a pool before he may ask for it back.
         *
         * Measured from his **first** allocation into that pool, not the latest — otherwise
         * topping up would restart his clock. Zero is no minimum, which is how the system behaved
         * before this existed.
         */
        public int $minimumTermMonths,
    ) {}

    /**
     * @param  array<string, mixed>  $data  already validated
     */
    public static function fromArray(array $data): self
    {
        return new self(
            investorProfitSharePercent: number_format(
                (float) $data['investor_profit_share_percent'], 2, '.', ''
            ),
            profitPeriodMonths: (int) $data['profit_period_months'],
            settlementPeriodMonths: (int) $data['settlement_period_months'],
            entryGraceDays: (int) $data['entry_grace_days'],
            minimumTermMonths: (int) $data['minimum_term_months'],
        );
    }
}
