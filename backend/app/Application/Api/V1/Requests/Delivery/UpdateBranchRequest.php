<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Delivery;

use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\Currency;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Exists;
use Illuminate\Validation\Validator;

/**
 * One branch's settings, sent whole — INSTANT-ORDERS-PLAN.md §8.
 *
 * Every account must be an active dinar account of the kind its method lands in: the cash box a
 * cash account, the transfer and card accounts bank accounts. Null leaves a method unset, and an
 * instant sale paid that way is then refused with a clear message.
 */
class UpdateBranchRequest extends FormRequest
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
            'is_branch_active' => ['required', 'boolean'],
            'default_warehouse_id' => ['nullable', 'integer', Rule::exists('warehouses', 'id')->withoutTrashed()],
            'cash_account_id' => ['nullable', 'integer', $this->account(AccountKind::Cash)],
            'bank_transfer_account_id' => ['nullable', 'integer', $this->account(AccountKind::Bank)],
            'bank_card_account_id' => ['nullable', 'integer', $this->account(AccountKind::Bank)],
            'employee_ids' => ['present', 'array'],
            'employee_ids.*' => ['integer', Rule::exists('users', 'id')->withoutTrashed()],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $branch = $this->route('branch');

            if ($branch instanceof City && $branch->fulfilment_type !== FulfilmentType::OfficePickup) {
                $validator->errors()->add('branch', 'الفرع يجب أن يكون مكتب استلام');
            }
        });
    }

    private function account(AccountKind $kind): Exists
    {
        return Rule::exists('treasury_accounts', 'id')
            ->where('kind', $kind->value)
            ->where('currency', Currency::Lyd->value)
            ->where('is_active', true);
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'default_warehouse_id.exists' => 'المخزن غير موجود',
            'cash_account_id.exists' => 'حساب الكاش يجب أن يكون حساباً نقدياً مفعّلاً بالدينار',
            'bank_transfer_account_id.exists' => 'حساب الحوالة يجب أن يكون حساب مصرف مفعّلاً بالدينار',
            'bank_card_account_id.exists' => 'حساب البطاقة يجب أن يكون حساب مصرف مفعّلاً بالدينار',
            'employee_ids.*.exists' => 'الموظف غير موجود',
        ];
    }
}
