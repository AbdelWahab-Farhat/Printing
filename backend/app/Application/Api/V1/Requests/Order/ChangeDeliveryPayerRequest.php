<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Enums\DeliveryPayer;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * «التوصيل على: المستلم / علينا». The permission is on the route, like every one-field order
 * endpoint; whether the order still allows it is the domain's answer.
 */
class ChangeDeliveryPayerRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** `recipient` — the recipient pays the courier at the door; `us` — we pay. */
            'delivery_paid_by' => ['required', Rule::enum(DeliveryPayer::class)],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'delivery_paid_by.required' => 'حدّد من يدفع التوصيل',
            'delivery_paid_by.enum' => 'من يدفع التوصيل: المستلم أو نحن',
        ];
    }
}
