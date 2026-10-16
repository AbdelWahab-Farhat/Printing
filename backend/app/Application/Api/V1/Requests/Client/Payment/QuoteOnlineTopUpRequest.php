<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Payment;

use App\Domain\OnlinePayment\Enums\OnlineMethod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** «تضيف ١٠٠ ← تدفع ١٠٥» — what a top-up would cost, before it starts. */
class QuoteOnlineTopUpRequest extends FormRequest
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
            'method' => ['required', 'integer', Rule::enum(OnlineMethod::class)],
            'amount' => ['required', 'decimal:0,2', 'min:1', 'max:100000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'method.enum' => 'طريقة الدفع غير معروفة',
            'amount.min' => 'أقل مبلغ للشحن دينار واحد',
            'amount.decimal' => 'المبلغ بخانتين عشريتين على الأكثر',
        ];
    }
}
