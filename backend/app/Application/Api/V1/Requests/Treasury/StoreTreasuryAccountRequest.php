<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Treasury;

use App\Domain\Treasury\Enums\AccountKind;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreTreasuryAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'kind' => ['required', Rule::enum(AccountKind::class)],
            // «مصرف علي» — whose name the account is in. A removed employee cannot be given one.
            'holder_user_id' => ['nullable', 'integer', Rule::exists('users', 'id')->whereNull('deleted_at')],
            'is_default' => ['nullable', 'boolean'],
            // «خزنة مكتب الاستلام» — a branch customers collect from; cash accounts only (§١٩).
            'pickup_city_id' => ['nullable',
                'integer',
                Rule::exists('cities', 'id')->where('fulfilment_type', 'office_pickup')->whereNull('deleted_at'),
            ],
            // «يُجمَع عند التسوية» — TREASURY-DESIGN §١٨.
            'is_collected' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string', 'max:1000'],
            // Custody only — the rule lives in SettlesIntoRule.
            'settles_into_account_id' => [
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
            'kind.required' => 'نوع الحساب مطلوب',
            'kind.enum' => 'نوع الحساب غير معروف',
            'holder_user_id.exists' => 'الموظف غير موجود',
            'pickup_city_id.exists' => 'ليس مكتب استلام',
        ];
    }

    public function attributes(): array
    {
        return [
            'name' => 'اسم الحساب',
            'kind' => 'نوع الحساب',
            'holder_user_id' => 'صاحب الحساب',
            'is_default' => 'الحساب الافتراضي',
            'is_collected' => 'يُجمَع عند التسوية',
            'pickup_city_id' => 'خزنة مكتب الاستلام',
            'notes' => 'الملاحظات',
        ];
    }
}
