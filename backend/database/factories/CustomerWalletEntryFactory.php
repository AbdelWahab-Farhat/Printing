<?php

namespace Database\Factories;

use App\Domain\Customer\Models\Customer;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CustomerWalletEntry>
 *
 * **A row only, with no treasury movement beside it** — for tests that read wallets. A test of
 * money moving goes through `WalletService`, which writes both.
 */
class CustomerWalletEntryFactory extends Factory
{
    /** @var class-string<CustomerWalletEntry> */
    protected $model = CustomerWalletEntry::class;

    /**
     * A credit adjustment by default — the only row that needs nothing else to exist first.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'customer_id' => Customer::factory(),
            'type' => WalletEntryType::AdjustmentCredit,
            'amount' => '100.00',
            'occurred_at' => now(),
            'notes' => 'رصيد تجريبي',
        ];
    }
}
