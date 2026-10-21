<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

/**
 * The vendor's cost for one unit of a وسيط line that went past «جاهزة» without one.
 *
 * Both grants are on the route — `orders.manage` to change the order, `products.view_cost` to
 * name the figure — so there is nothing left for `authorize()` to decide.
 */
class RecordVendorCostRequest extends FormRequest
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
            'unit_cost' => ['required', 'numeric', 'min:0', 'max:9999999.999'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'unit_cost.required' => 'تكلفة المورد مطلوبة',
            'unit_cost.numeric' => 'تكلفة المورد يجب أن تكون رقماً',
            'unit_cost.min' => 'تكلفة المورد لا يمكن أن تكون سالبة',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['unit_cost' => 'تكلفة المورد'];
    }
}
