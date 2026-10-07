<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Marking an entry reviewed — or taking the review back.
 *
 * The permission is on the route (`orders.payments.review`). What else may refuse a review — a
 * reversed or exempt entry — is a fact about the row rather than the request, so it lives in
 * `OrderPayment::reviewRefusal()`, where a console command meets it too, and reaches the app as
 * `can_review`.
 *
 * **`reviewed` is required and not defaulted**, exactly as `received` is on the deposit
 * endpoint: a missing key would silently mean «نعم» on the one request whose other direction is
 * the correction of a stray tap.
 */
class ReviewOrderPaymentRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** Whether the entry has been checked and is right. `false` takes an earlier review back. */
            'reviewed' => ['required', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'reviewed.required' => 'حدّد ما إذا كانت الدفعة قد رُوجعت',
            'reviewed.boolean' => 'قيمة المراجعة يجب أن تكون نعم أو لا',
        ];
    }
}
