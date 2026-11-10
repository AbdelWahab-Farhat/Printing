<?php

namespace Tests\Unit;

use App\Domain\Order\Support\Money;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

/**
 * A line in whole dinars: the fraction dropped, down, but never down to nothing.
 *
 * Arrange - Act - Assert throughout.
 */
class MoneyWholeDinarsTest extends TestCase
{
    /**
     * @return array<string, array{string, string}>
     */
    public static function amounts(): array
    {
        return [
            'a fraction drops' => ['183.300000', '183.00'],
            'a high fraction drops too' => ['331.990000', '331.00'],
            'a whole amount stays' => ['250.000000', '250.00'],
            'under a dinar bills one' => ['0.800000', '1.00'],
            'exactly one stays one' => ['1.000000', '1.00'],
            'nothing stays nothing' => ['0.000000', '0.00'],
        ];
    }

    #[DataProvider('amounts')]
    public function test_a_line_is_billed_in_whole_dinars(string $exact, string $billed): void
    {
        // Act
        $actual = Money::wholeDinars($exact);

        // Assert
        $this->assertSame($billed, $actual);
    }

    public function test_whole_means_no_fraction_at_all(): void
    {
        // Assert
        $this->assertTrue(Money::isWhole('25.00'));
        $this->assertTrue(Money::isWhole('0.00'));
        $this->assertFalse(Money::isWhole('25.50'));
        $this->assertFalse(Money::isWhole('25.01'));
    }
}
