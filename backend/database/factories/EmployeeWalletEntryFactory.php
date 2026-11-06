<?php

namespace Database\Factories;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<EmployeeWalletEntry>
 *
 * **سطرٌ وحده بلا حركة خزينة بجانبه** — لاختبارات تقرأ المحافظ. اختبارُ مالٍ يتحرك يمرّ بالخدمة،
 * وهي تكتب الاثنين.
 */
class EmployeeWalletEntryFactory extends Factory
{
    /** @var class-string<EmployeeWalletEntry> */
    protected $model = EmployeeWalletEntry::class;

    /**
     * تعديلٌ بالزيادة افتراضاً — السطرُ الوحيد الذي لا يحتاج شيئاً قبله.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'type' => EmployeeWalletEntryType::AdjustmentCredit,
            'amount' => '100.00',
            'occurred_at' => now(),
            'notes' => 'رصيد تجريبي',
        ];
    }

    public function debit(): self
    {
        return $this->state(['type' => EmployeeWalletEntryType::AdjustmentDebit]);
    }
}
