<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Wallet;

use Illuminate\Foundation\Http\FormRequest;

/** Undoing a wallet row — a reason is required, as for every reversal. */
class ReverseWalletEntryRequest extends FormRequest
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
            'reason' => ['required', 'string', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'reason.required' => 'سبب العكس مطلوب',
            'reason.max' => 'السبب طويل جداً',
        ];
    }
}
