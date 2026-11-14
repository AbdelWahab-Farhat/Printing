<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Enums\CompensationReason;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * «طلبية تعويض» on an existing order. `orders.manage` is on the route; `orders.compensation`
 * and whether the order still allows it are the domain's answers.
 */
class ChangeOrderCompensationRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** True turns the order into a compensation order (total 0); false turns it back. */
            'is_compensation' => ['required', 'boolean'],
            'compensation_reason' => [
                Rule::requiredIf(fn (): bool => $this->boolean('is_compensation')),
                'nullable',
                Rule::enum(CompensationReason::class),
            ],
            'compensation_note' => [
                Rule::requiredIf(fn (): bool => $this->boolean('is_compensation')
                    && $this->input('compensation_reason') === CompensationReason::Other->value),
                'nullable',
                'string',
                'max:500',
            ],
            /** The order being made good. Optional. */
            'compensates_order_id' => ['nullable', 'integer', Rule::exists('orders', 'id')->withoutTrashed()],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'is_compensation' => 'طلبية تعويض',
            'compensation_reason' => 'سبب التعويض',
            'compensation_note' => 'ملاحظة التعويض',
            'compensates_order_id' => 'الطلبية الأصلية',
        ];
    }
}
