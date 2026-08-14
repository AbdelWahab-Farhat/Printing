<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Inventory;

use App\Domain\Catalog\Enums\PricingUnit;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Declares what a product's stock is counted in — see {@see \App\Domain\Inventory\Actions\SetStockUnit}.
 */
class SetStockUnitRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'unit' => ['required', Rule::enum(PricingUnit::class)],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'unit.required' => 'الوحدة مطلوبة',
            'unit.enum' => 'الوحدة غير صحيحة',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'unit' => 'الوحدة',
        ];
    }
}
