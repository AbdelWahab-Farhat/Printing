<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Actions;

use App\Domain\Delivery\DTOs\ShippingCompanyData;
use App\Domain\Delivery\Models\ShippingCompany;

final class UpdateShippingCompany
{
    public function __invoke(ShippingCompany $company, ShippingCompanyData $data): ShippingCompany
    {
        $company->update([
            'name' => $data->name,
            'phone' => $data->phone,
            'notes' => $data->notes,
            'is_active' => $data->isActive,
        ]);

        return $company;
    }
}
