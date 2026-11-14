<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Confirming — or unconfirming — that the customer was contacted about their returned order.
 *
 * Same body and same rules as {@see ConfirmReadyMessageRequest}: `sent` is required, because a
 * missing key silently meaning «نعم» is worst on an endpoint whose other direction is a
 * correction.
 */
class ConfirmReturnMessageRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** Whether the customer has been contacted. `false` takes an earlier confirmation back. */
            'sent' => ['required', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'sent.required' => 'حدّد ما إذا كان قد تم التواصل مع الزبون',
            'sent.boolean' => 'قيمة التواصل يجب أن تكون نعم أو لا',
        ];
    }
}
