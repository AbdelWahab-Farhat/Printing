<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Treasury\Enums\OperationType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * One hand operation. Which fields it needs depends on its type, and so does who may send it:
 *
 * | type | needs | grant |
 * | --- | --- | --- |
 * | opening | to_account_id, amount | treasury.manage |
 * | deposit | to_account_id, amount | treasury.record |
 * | withdrawal | from_account_id, amount, notes | treasury.record |
 * | expense | from_account_id, amount, category_id (employee_id for «سلفة») | treasury.record |
 * | transfer | from_account_id, to_account_id, amount | treasury.record |
 * | adjustment | to_account_id (the account counted), counted_balance, notes | treasury.adjust |
 */
class StoreTreasuryOperationRequest extends FormRequest
{
    /**
     * The grant turns on the body, so it is checked here rather than in route middleware — the
     * `ChangeOrderStatusRequest` arrangement. An unknown type is left to `rules()` to refuse.
     */
    public function authorize(): bool
    {
        $type = OperationType::tryFrom((string) $this->input('type'));

        $permission = match ($type) {
            OperationType::Opening => PermissionName::ManageTreasury,
            OperationType::Adjustment => PermissionName::AdjustTreasuryBalances,
            null => null,
            default => PermissionName::RecordTreasuryOperations,
        };

        return $permission === null || (bool) $this->user()?->can($permission->value);
    }

    public function rules(): array
    {
        $account = Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at');

        return [
            'type' => ['required', Rule::in(array_map(
                fn (OperationType $type) => $type->value,
                OperationType::recordable(),
            ))],

            // خانتان عشريتان على الأكثر ودرهمٌ على الأقل: 0.001 كان يمرّ من `gt:0` ثم يُقرَّب إلى
            // صفر فيصطدم بقيد القاعدة ويخرج 500 بدل رسالة.
            'amount' => [
                'exclude_if:type,adjustment',
                'required',
                'decimal:0,2',
                'min:0.01',
                'max:9999999999',
            ],

            'from_account_id' => [
                'exclude_unless:type,withdrawal,expense,transfer',
                'required',
                'integer',
                $account,
            ],
            'to_account_id' => [
                'exclude_unless:type,opening,deposit,transfer,adjustment',
                'required',
                'integer',
                'different:from_account_id',
                $account,
            ],

            'category_id' => [
                'exclude_unless:type,expense',
                'required',
                'integer',
                Rule::exists('treasury_expense_categories', 'id')->whereNull('deleted_at'),
            ],
            // موظّفٌ حُذف لا تُكتب له سلفة — صفُّه باقٍ في الجدول، فالحذفُ الناعم يُستثنى صراحة.
            'employee_id' => [
                'exclude_unless:type,expense',
                'nullable',
                'integer',
                Rule::exists('users', 'id')->whereNull('deleted_at'),
            ],

            // What was actually counted. Zero is a real answer — an empty drawer.
            'counted_balance' => [
                'exclude_unless:type,adjustment',
                'required',
                'decimal:0,2',
                'min:0',
                'max:9999999999',
            ],

            'occurred_at' => ['nullable', 'date', 'before_or_equal:now'],

            // A count always says why. A withdrawal does too unless the owner switched that off in
            // «إعدادات المالية» — so that half is the Action's, which reads the setting.
            'notes' => ['required_if:type,adjustment', 'nullable', 'string', 'max:1000'],

            // يولّده التطبيق قبل الإرسال: الضغطةُ الثانية بالرمز نفسه تُرجع العمليةَ الأولى.
            'client_token' => ['nullable', 'uuid'],
        ];
    }

    public function messages(): array
    {
        return [
            'type.required' => 'نوع العملية مطلوب',
            'type.in' => 'نوع العملية غير معروف',
            'amount.required' => 'المبلغ مطلوب',
            'amount.decimal' => 'المبلغ رقمٌ بخانتين عشريتين على الأكثر',
            'amount.min' => 'المبلغ يجب أن يكون 0.01 على الأقل',
            'amount.max' => 'المبلغ أكبر من الحد المسموح',
            'from_account_id.required' => 'الحساب المسحوب منه مطلوب',
            'from_account_id.exists' => 'الحساب غير موجود',
            'to_account_id.required' => 'الحساب مطلوب',
            'to_account_id.exists' => 'الحساب غير موجود',
            'to_account_id.different' => 'لا يُحوَّل من حساب إلى نفسه',
            'category_id.required' => 'تصنيف المصروف مطلوب',
            'category_id.exists' => 'التصنيف غير موجود',
            'employee_id.exists' => 'الموظف غير موجود',
            'counted_balance.required' => 'الرصيد المعدود مطلوب',
            'counted_balance.decimal' => 'الرصيد المعدود رقمٌ بخانتين عشريتين على الأكثر',
            'counted_balance.min' => 'الرصيد المعدود لا يكون سالباً',
            'occurred_at.date' => 'التاريخ غير صحيح',
            'occurred_at.before_or_equal' => 'التاريخ لا يكون في المستقبل',
            'notes.required_if' => 'السبب مطلوب لهذه العملية',
            'client_token.uuid' => 'رمز الإرسال غير صالح',
        ];
    }

    public function attributes(): array
    {
        return [
            'type' => 'نوع العملية',
            'amount' => 'المبلغ',
            'from_account_id' => 'من حساب',
            'to_account_id' => 'إلى حساب',
            'category_id' => 'تصنيف المصروف',
            'employee_id' => 'الموظف',
            'counted_balance' => 'الرصيد المعدود',
            'occurred_at' => 'التاريخ',
            'notes' => 'الملاحظات',
            'client_token' => 'رمز الإرسال',
        ];
    }
}
