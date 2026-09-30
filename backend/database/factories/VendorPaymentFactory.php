<?php

namespace Database\Factories;

use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * An opening debt by default — the one row shape that needs no account and posts no movement.
 * Real payments are recorded through `RecordVendorPayment`, which is what moves the money.
 *
 * @extends Factory<VendorPayment>
 */
class VendorPaymentFactory extends Factory
{
    protected $model = VendorPayment::class;

    public function definition(): array
    {
        return [
            'vendor_id' => Vendor::factory(),
            'type' => VendorPaymentType::OpeningDebt,
            'amount' => '500.00',
            'paid_at' => now(),
        ];
    }
}
