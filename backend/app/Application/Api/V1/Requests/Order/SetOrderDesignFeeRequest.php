<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Support\Money;
use Closure;
use Illuminate\Foundation\Http\FormRequest;

/**
 * «أجرة التصميم» on an existing order. `orders.design_fee` is on the route; whether the order still
 * takes it is the domain's answer. See Docs/orders/ORDER-DESIGN-FEE.md.
 */
class SetOrderDesignFeeRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** Whole dinars. `0` clears it, and is still a decision no ticket overrides. */
            'design_fee' => ['required', 'numeric', 'min:0', 'max:9999999999.99', $this->wholeDinars()],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'design_fee.required' => 'اكتب أجرة التصميم، أو 0 بلا أجرة',
            'design_fee.numeric' => 'أجرة التصميم يجب أن تكون رقماً',
            'design_fee.min' => 'أجرة التصميم لا يمكن أن تكون سالبة',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['design_fee' => 'أجرة التصميم'];
    }

    public function fee(): string
    {
        return Money::normalize($this->validated('design_fee'));
    }

    private function wholeDinars(): Closure
    {
        return function (string $attribute, mixed $value, Closure $fail): void {
            if (is_numeric($value) && ! Money::isWhole(Money::normalize($value))) {
                $fail(':attribute بالدينار الكامل، بلا كسور');
            }
        };
    }
}
