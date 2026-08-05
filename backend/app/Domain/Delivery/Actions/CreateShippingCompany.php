<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Actions;

use App\Domain\Delivery\DTOs\ShippingCompanyData;
use App\Domain\Delivery\Models\ShippingCompany;

final class CreateShippingCompany
{
    public function __invoke(ShippingCompanyData $data): ShippingCompany
    {
        return ShippingCompany::create([
            'name' => $data->name,
            'phone' => $data->phone,
            'notes' => $data->notes,
            'is_active' => $data->isActive,
        ]);
    }
}
