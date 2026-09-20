<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Domain\Settings\SettingsService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * Company settings
 *
 * The handful of defaults the business edits from a screen rather than from a deploy.
 *
 * **A default is not a rate that reaches back.** `investor_profit_share_percent` seeds a new
 * deal and is never read again for that deal, so changing it tomorrow decides what the next deal
 * is born with and moves nothing that has already been agreed or paid.
 */
class CompanySettingController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly SettingsService $settings) {}

    /**
     * Read the company settings
     */
    public function show(): JsonResponse
    {
        $settings = $this->settings->current();

        return $this->success([
            'investor_profit_share_percent' => (string) $settings->investor_profit_share_percent,

            // المدد الأربع كأعدادٍ صحيحة لا كنصوص: التطبيق يرسمها في حقول عددٍ ويحسب بها مواعيد،
            // ونصٌّ هنا يعني تحويلاً في كل قارئ.
            'investment_period_months' => (int) $settings->investment_period_months,
            'investment_subscription_window_days' => (int) $settings->investment_subscription_window_days,
            'investment_settlement_months' => (int) $settings->investment_settlement_months,
            'investment_capital_lock_months' => (int) $settings->investment_capital_lock_months,

            'updated_at' => $settings->updated_at?->toIso8601String(),
        ]);
    }

    /**
     * Update the company settings
     */
    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'investor_profit_share_percent' => ['required', 'numeric', 'min:0', 'max:100'],

            // المدد كلُّها اختيارية: شاشةٌ تعدّل النسبة وحدها لا يجوز أن تُجبَر على إعادة إرسال
            // أربعة أرقامٍ لم تمسّها، وما لم يصل يبقى كما هو.
            'investment_period_months' => ['sometimes', 'integer', 'min:1', 'max:12'],
            'investment_subscription_window_days' => ['sometimes', 'integer', 'min:1', 'max:28'],
            'investment_settlement_months' => ['sometimes', 'integer', 'min:1', 'max:36'],
            'investment_capital_lock_months' => ['sometimes', 'integer', 'min:0', 'max:120'],
        ], [
            'investor_profit_share_percent.required' => 'نسبة المستثمرين مطلوبة',
            'investor_profit_share_percent.max' => 'النسبة لا تتجاوز 100',
            'investment_period_months.min' => 'مدة الفترة شهرٌ على الأقل',
            'investment_subscription_window_days.max' => 'نافذة الاكتتاب لا تتجاوز ٢٨ يوماً',
            'investment_capital_lock_months.min' => 'مدة الحجز لا تكون سالبة',
        ]);

        // **المضاعَفُ يُفحص هنا وفي القاعدة معاً.** القيدُ في القاعدة يمنع الكتابة مهما كان
        // الطريق؛ وهذا يُخرج رسالةً عربيةً يقرأها من يملأ الشاشة بدل خطأ SQL بخمسمئة.
        $durations = array_intersect_key($validated, array_flip([
            'investment_period_months',
            'investment_subscription_window_days',
            'investment_settlement_months',
            'investment_capital_lock_months',
        ]));

        $current = $this->settings->current();
        $period = $durations['investment_period_months'] ?? (int) $current->investment_period_months;
        $settlement = $durations['investment_settlement_months'] ?? (int) $current->investment_settlement_months;

        if ($period > 0 && $settlement % $period !== 0) {
            throw ValidationException::withMessages([
                'investment_settlement_months' => "مدة التسوية يجب أن تكون مضاعفاً لمدة الفترة ({$period} شهر) — وإلا قُطعت فترةٌ في منتصفها",
            ]);
        }

        $settings = $this->settings->update(
            number_format((float) $validated['investor_profit_share_percent'], 2, '.', ''),
            $request->user()?->id,
            $durations,
        );

        return $this->success([
            'investor_profit_share_percent' => (string) $settings->investor_profit_share_percent,
            'investment_period_months' => (int) $settings->investment_period_months,
            'investment_subscription_window_days' => (int) $settings->investment_subscription_window_days,
            'investment_settlement_months' => (int) $settings->investment_settlement_months,
            'investment_capital_lock_months' => (int) $settings->investment_capital_lock_months,
        ], 'تم تحديث الإعدادات — تسري على ما يُفتح بعدها ولا تمسّ فترةً قائمة');
    }
}
