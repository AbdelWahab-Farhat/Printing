<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Domain\Investor\Enums\WalletEntryCategory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * The query string an investor's statement accepts — on the staff route and on the portal.
 *
 * A FormRequest for a GET for the reason {@see ActivityLogFilterRequest}
 * gives: a date that does not parse should be a readable 422, not an empty page read as «he
 * never moved any money».
 */
class InvestorStatementRequest extends FormRequest
{
    /** Access is declared on the routes; there is nothing extra to decide here. */
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
            // One of capital · investment · profit · loss. A reversal follows the row it undoes.
            'category' => ['sometimes', 'nullable', Rule::in(WalletEntryCategory::values())],

            // Only the rows of one deal, or of the fund.
            'investor_deal_id' => ['sometimes', 'nullable', 'integer', 'min:1'],

            // Inclusive on both ends: `to` counts the whole of its day.
            'from' => ['sometimes', 'nullable', 'date'],
            'to' => ['sometimes', 'nullable', 'date', 'after_or_equal:from'],

            // Not validated, clamped — see perPage(). Declared so it appears in the spec.
            'per_page' => ['sometimes', 'integer'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'category.in' => 'نوع الحركة غير صحيح',
            'investor_deal_id.integer' => 'معرف الصفقة غير صحيح',
            'from.date' => 'تاريخ البداية غير صحيح',
            'to.date' => 'تاريخ النهاية غير صحيح',
            'to.after_or_equal' => 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية',
        ];
    }

    /**
     * @return array{category?: ?string, investor_deal_id?: ?int, from?: ?string, to?: ?string}
     */
    public function filters(): array
    {
        /** @var array{category?: ?string, investor_deal_id?: ?int, from?: ?string, to?: ?string} */
        return collect($this->validated())
            ->only(['category', 'investor_deal_id', 'from', 'to'])
            ->all();
    }

    /** Clamped, not rejected — the same treatment `per_page` gets on every other list here. */
    public function perPage(): int
    {
        return min(max((int) $this->integer('per_page', 25), 1), 100);
    }
}
