<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Treasury;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Every switch optional; an absent one is left as it is. `locked_until` sent as null unlocks.
 */
class UpdateTreasurySettingsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'own_account_first' => ['sometimes', 'boolean'],
            'block_overdraft' => ['sometimes', 'boolean'],
            'withdrawal_needs_reason' => ['sometimes', 'boolean'],
            'ask_carrier_fee' => ['sometimes', 'boolean'],
            // A lock in the future would refuse today's work before anybody had counted it.
            'locked_until' => ['sometimes', 'nullable', 'date', 'before_or_equal:today'],
            // «التجميع عند التسوية», per kind. A null target is the kind's default; that the
            // account is of the right kind is checked by UpdateTreasurySettings.
            'collect_cash' => ['sometimes', 'boolean'],
            'collect_bank' => ['sometimes', 'boolean'],
            'collect_wallet' => ['sometimes', 'boolean'],
            'collect_cash_into_id' => ['sometimes', 'nullable', 'integer', Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at')],
            'collect_bank_into_id' => ['sometimes', 'nullable', 'integer', Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at')],
            'collect_wallet_into_id' => ['sometimes', 'nullable', 'integer', Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at')],
            // «التسوية إلى حساب المسوّي» (§٢٢).
            'settle_into_settler' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'locked_until.date' => 'التاريخ غير صحيح',
            'locked_until.before_or_equal' => 'لا يُقفل تاريخٌ لم يأتِ بعد',
            'collect_cash_into_id.exists' => 'الحساب غير موجود',
            'collect_bank_into_id.exists' => 'الحساب غير موجود',
            'collect_wallet_into_id.exists' => 'الحساب غير موجود',
        ];
    }

    public function attributes(): array
    {
        return [
            'own_account_first' => 'الحساب الشخصي أولاً',
            'block_overdraft' => 'منع الرصيد السالب',
            'withdrawal_needs_reason' => 'السبب إجباري عند السحب',
            'ask_carrier_fee' => 'سؤال «احتفظ به الناقل»',
            'locked_until' => 'مقفل حتى تاريخ',
            'collect_cash' => 'تجميع النقد عند التسوية',
            'collect_bank' => 'تجميع المصارف عند التسوية',
            'collect_wallet' => 'تجميع المحافظ عند التسوية',
            'collect_cash_into_id' => 'يُجمع النقد في',
            'collect_bank_into_id' => 'تُجمع المصارف في',
            'collect_wallet_into_id' => 'تُجمع المحافظ في',
            'settle_into_settler' => 'التسوية إلى حساب المسوّي',
        ];
    }
}
