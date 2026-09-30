<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Treasury;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Every field optional; an absent one is left alone. `kind` is not accepted at all — see
 * `UpdateTreasuryAccount` for why an account's kind is fixed.
 */
class UpdateTreasuryAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'holder_user_id' => ['sometimes', 'nullable', 'integer', Rule::exists('users', 'id')->whereNull('deleted_at')],
            'is_default' => ['sometimes', 'boolean'],
            'is_active' => ['sometimes', 'boolean'],
            // «خزنة مكتب الاستلام» — a branch customers collect from; cash accounts only (§١٩).
            'pickup_city_id' => ['sometimes', 'nullable',
                'integer',
                Rule::exists('cities', 'id')->where('fulfilment_type', 'office_pickup')->whereNull('deleted_at'),
            ],
            // «يُجمَع عند التسوية» — TREASURY-DESIGN §١٨.
            'is_collected' => ['sometimes', 'boolean'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:1000'],
            // Custody only; a sent null clears it back to the built-in rule.
            'settles_into_account_id' => [
                'sometimes',
                'nullable',
                'integer',
                Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at'),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'اسم الحساب مطلوب',
            'name.max' => 'اسم الحساب طويل جداً',
            'holder_user_id.exists' => 'الموظف غير موجود',
            'pickup_city_id.exists' => 'ليس مكتب استلام',
        ];
    }

    public function attributes(): array
    {
        return [
            'name' => 'اسم الحساب',
            'holder_user_id' => 'صاحب الحساب',
            'is_default' => 'الحساب الافتراضي',
            'is_active' => 'مفعّل',
            'is_collected' => 'يُجمَع عند التسوية',
            'pickup_city_id' => 'خزنة مكتب الاستلام',
            'notes' => 'الملاحظات',
        ];
    }
}
