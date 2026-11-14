<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Confirming — or unconfirming — that the vendor was sent the job of an outsourced order.
 *
 * Same body and same rules as {@see ConfirmReadyMessageRequest}: `sent` is required, because a
 * missing key silently meaning «نعم» is worst on an endpoint whose other direction is a
 * correction.
 */
class ConfirmVendorMessageRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** Whether the vendor has been sent the message. `false` takes an earlier confirmation back. */
            'sent' => ['required', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'sent.required' => 'حدّد ما إذا كانت رسالة المورد قد أُرسلت',
            'sent.boolean' => 'قيمة الإرسال يجب أن تكون نعم أو لا',
        ];
    }
}
