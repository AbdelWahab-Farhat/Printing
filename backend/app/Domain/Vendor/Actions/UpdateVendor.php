<?php

declare(strict_types=1);

namespace App\Domain\Vendor\Actions;

use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\DTOs\VendorData;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Support\Facades\DB;

final class UpdateVendor
{
    public function __construct(private readonly TreasuryService $treasury) {}

    public function __invoke(Vendor $vendor, VendorData $data): Vendor
    {
        $attributes = [
            'name' => $data->name,
            'phone' => $data->phone,
            'contact_person' => $data->contactPerson,
            'email' => $data->email,
            'address' => $data->address,
        ];

        // Only touched when the caller actually sent it, so an update that omits the field
        // cannot reactivate a vendor who was deliberately deactivated.
        if ($data->isActive !== null) {
            $attributes['is_active'] = $data->isActive;
        }

        return DB::transaction(function () use ($vendor, $attributes): Vendor {
            $renamed = $attributes['name'] !== $vendor->name;

            $vendor->update($attributes);

            // «علينا» lists the vendor's debt under the vendor's name (TREASURY-DESIGN §٢٠).
            if ($renamed) {
                $this->treasury->renameVendorPayable((int) $vendor->getKey(), (string) $vendor->name);
            }

            return $vendor;
        });
    }
}
