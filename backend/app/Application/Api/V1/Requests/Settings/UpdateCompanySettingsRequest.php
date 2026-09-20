<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Settings;

use Illuminate\Foundation\Http\FormRequest;

/**
 * The whole settings screen, saved at once.
 *
 * **Every field is required, and that is deliberate.** These are four values on one form with one
 * button; a payload carrying three of them would silently reset the fourth to whatever the client
 * last believed it to be. Requiring all four makes a stale client fail loudly instead.
 *
 * The bounds mirror the `CHECK` constraints on the table exactly. Stated twice on purpose: the
 * database is what guarantees the invariant, and this is what turns a violation into an Arabic
 * sentence instead of a 500.
 */
class UpdateCompanySettingsRequest extends FormRequest
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
            'investor_profit_share_percent' => ['required', 'numeric', 'min:0', 'max:100'],
            'profit_period_months' => ['required', 'integer', 'min:1', 'max:12'],
            'settlement_period_months' => ['required', 'integer', 'min:1', 'max:24'],
            // 28 rather than 31: the shortest month has 28 days, and a window that could outlast
            // February would sometimes swallow a whole period.
            'entry_grace_days' => ['required', 'integer', 'min:0', 'max:28'],
            // **Zero is the meaningful default**, and it is today's behaviour: an exit may be
            // asked for at any time. The ceiling is a typo guard rather than a policy — «120»
            // where «12» was meant would lock somebody in for a decade.
            'minimum_term_months' => ['required', 'integer', 'min:0', 'max:24'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'investor_profit_share_percent.required' => 'نسبة المستثمرين مطلوبة',
            'investor_profit_share_percent.max' => 'النسبة لا تتجاوز 100',
            'profit_period_months.required' => 'مدة إغلاق الأرباح مطلوبة',
            'profit_period_months.min' => 'مدة إغلاق الأرباح شهر واحد على الأقل',
            'profit_period_months.max' => 'مدة إغلاق الأرباح لا تتجاوز 12 شهراً',
            'settlement_period_months.required' => 'مدة التسوية مطلوبة',
            'settlement_period_months.min' => 'مدة التسوية شهر واحد على الأقل',
            'settlement_period_months.max' => 'مدة التسوية لا تتجاوز 24 شهراً',
            'entry_grace_days.required' => 'مهلة دخول رأس المال مطلوبة',
            'entry_grace_days.min' => 'المهلة لا تقل عن صفر',
            'entry_grace_days.max' => 'المهلة لا تتجاوز 28 يوماً',
            'minimum_term_months.required' => 'الحد الأدنى للبقاء مطلوب',
            'minimum_term_months.min' => 'الحد الأدنى لا يقل عن صفر',
            'minimum_term_months.max' => 'الحد الأدنى لا يتجاوز 24 شهراً',
        ];
    }
}
