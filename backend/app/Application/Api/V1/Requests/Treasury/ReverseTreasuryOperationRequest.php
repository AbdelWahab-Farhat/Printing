<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Treasury;

use Illuminate\Foundation\Http\FormRequest;

class ReverseTreasuryOperationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return ['reason.required' => 'سبب العكس مطلوب'];
    }

    public function attributes(): array
    {
        return ['reason' => 'سبب العكس'];
    }
}
