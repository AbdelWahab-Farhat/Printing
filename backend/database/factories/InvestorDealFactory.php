<?php

namespace Database\Factories;

use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PoolKind;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestorDeal>
 */
class InvestorDealFactory extends Factory
{
    /** @var class-string<InvestorDeal> */
    protected $model = InvestorDeal::class;

    private static int $sequence = 0;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            // A legacy صفقة by default, so every test written before pools existed goes on
            // building exactly what it used to.
            'kind' => PoolKind::Deal,
            'status' => DealStatus::Draft,
            'investor_profit_share_percent' => '50.00',
            'opened_on' => now()->toDateString(),
        ];
    }

    /** A deal that has been opened and may take stock. */
    public function open(): self
    {
        return $this->state(fn () => [
            'status' => DealStatus::Open,
            'opened_at' => now(),
        ]);
    }

    /**
     * A صندوق — open from birth and never closed.
     *
     * The name is sequenced rather than random because the unique index on a pool's name is
     * real, and two pools built in one test must not collide on «ورق».
     */
    public function pool(): self
    {
        return $this->state(fn () => [
            'kind' => PoolKind::Pool,
            'name' => 'صندوق '.(++self::$sequence),
            'status' => DealStatus::Open,
            'opened_at' => now(),
        ]);
    }
}
