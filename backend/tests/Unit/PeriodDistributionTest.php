<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Domain\Investor\Support\PeriodDistribution;
use PHPUnit\Framework\TestCase;

/**
 * The sums a person will argue with.
 *
 * Pure arithmetic — no database, no clock, no pool — which is the point: the part of the close that
 * decides who gets what should be checkable by hand, against a table written on paper.
 *
 * Arrange - Act - Assert throughout.
 */
class PeriodDistributionTest extends TestCase
{
    public function test_the_worked_example_from_the_design(): void
    {
        // Arrange — capital 350,000: A 120,000 · B 80,000 · C 80,000 · company 70,000.
        // Net profit 28,000, investors' share 50%.
        $capital = [1 => '120000.00', 2 => '80000.00', 3 => '80000.00', 9 => '70000.00'];

        // Act
        $result = PeriodDistribution::divide('28000.00', $capital, companyInvestorId: 9, investorSharePercent: '50.00');

        // Assert — investors own 280,000 of 350,000, so 80% of the goods; half of what that earns
        $this->assertSame('80.0000', $result['investor_weight_percent']);
        $this->assertSame('11200.00', $result['investors_side']);
        $this->assertSame('16800.00', $result['company_total']);

        $this->assertSame('4800.00', $result['per_investor'][1]['net_share']);
        $this->assertSame('3200.00', $result['per_investor'][2]['net_share']);
        $this->assertSame('3200.00', $result['per_investor'][3]['net_share']);

        // The company is not among the investors' shares — its capital earned it a weight, and its
        // operator's half is the residual
        $this->assertArrayNotHasKey(9, $result['per_investor']);
    }

    public function test_with_no_company_capital_it_is_the_plain_fifty_fifty(): void
    {
        // Arrange
        $capital = [1 => '120000.00', 2 => '80000.00'];

        // Act
        $result = PeriodDistribution::divide('10000.00', $capital, companyInvestorId: null, investorSharePercent: '50.00');

        // Assert — the weight vanishes and the two-step formula is what is left
        $this->assertSame('100.0000', $result['investor_weight_percent']);
        $this->assertSame('5000.00', $result['investors_side']);
        $this->assertSame('5000.00', $result['company_total']);
        $this->assertSame('3000.00', $result['per_investor'][1]['net_share']);
        $this->assertSame('2000.00', $result['per_investor'][2]['net_share']);
    }

    public function test_the_parts_always_sum_to_the_whole(): void
    {
        // Arrange — three equal investors against a figure that does not divide by three
        $capital = [1 => '10000.00', 2 => '10000.00', 3 => '10000.00'];

        // Act
        $result = PeriodDistribution::divide('100.01', $capital, companyInvestorId: null, investorSharePercent: '100.00');

        // Assert — largest-remainder: no dinar invented, none lost
        $sum = '0.00';

        foreach ($result['per_investor'] as $share) {
            $sum = bcadd($sum, $share['net_share'], 2);
        }

        $this->assertSame($result['investors_side'], $sum);
        $this->assertSame(
            '100.01',
            bcadd($result['investors_side'], $result['company_total'], 2),
        );
    }

    public function test_a_loss_divides_by_the_same_rule_with_the_sign_carried(): void
    {
        // Arrange
        $capital = [1 => '120000.00', 2 => '80000.00', 9 => '50000.00'];

        // Act
        $result = PeriodDistribution::divide('-10000.00', $capital, companyInvestorId: 9, investorSharePercent: '50.00');

        // Assert — investors own 200,000 of 250,000 = 80%; half of the loss on that is -4,000
        $this->assertSame('80.0000', $result['investor_weight_percent']);
        $this->assertSame('-4000.00', $result['investors_side']);
        $this->assertSame('-6000.00', $result['company_total']);
        $this->assertSame('-2400.00', $result['per_investor'][1]['net_share']);
        $this->assertSame('-1600.00', $result['per_investor'][2]['net_share']);
    }

    public function test_a_pool_with_no_capital_gives_everything_to_the_company(): void
    {
        // Arrange — it sold the last of its goods and returned every dinar, then earned
        // Act
        $result = PeriodDistribution::divide('500.00', [], companyInvestorId: null, investorSharePercent: '50.00');

        // Assert — nobody's money was at work, so nobody has a claim
        $this->assertSame('0.00', $result['investors_side']);
        $this->assertSame('500.00', $result['company_total']);
        $this->assertSame([], $result['per_investor']);
    }

    public function test_a_company_that_owns_almost_everything_leaves_the_investors_almost_nothing(): void
    {
        // Arrange — the shape D1 is really in: the partners bought 93.1808% of the goods
        $capital = [1 => '93180.80', 9 => '6819.20'];

        // Act
        $result = PeriodDistribution::divide('1000.00', $capital, companyInvestorId: 9, investorSharePercent: '50.00');

        // Assert — 1000 × 93.1808% × 50%
        $this->assertSame('93.1808', $result['investor_weight_percent']);
        $this->assertSame('465.90', $result['investors_side']);
        $this->assertSame('534.10', $result['company_total']);
    }

    public function test_a_share_percent_is_of_the_investors_side_not_of_the_whole(): void
    {
        // Arrange — the split `investor_deal_shares` always made, kept for the same reason
        $capital = [1 => '75000.00', 2 => '25000.00', 9 => '100000.00'];

        // Act
        $result = PeriodDistribution::divide('8000.00', $capital, companyInvestorId: 9, investorSharePercent: '50.00');

        // Assert — A holds three quarters of the investors' money, not of the pool's
        $this->assertSame('75.0000', $result['per_investor'][1]['share_percent']);
        $this->assertSame('25.0000', $result['per_investor'][2]['share_percent']);
        $this->assertSame('50.0000', $result['investor_weight_percent']);
        $this->assertSame('2000.00', $result['investors_side']);
        $this->assertSame('1500.00', $result['per_investor'][1]['net_share']);
        $this->assertSame('500.00', $result['per_investor'][2]['net_share']);
    }
}
