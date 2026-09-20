<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use App\Domain\Investor\Enums\CapitalRequestDirection;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Capital offered to a pool, or asked back from it.
 *
 * **No period and no effective date.** Both are derived from the pool's current period and the
 * company's grace setting — a payload that could name the period it joins could put a man into a
 * period he was never in, and pay him for a month he did not fund.
 *
 * **No minimum stake.** `FundPurchaseOrder` has one, because a deal froze its partners at the
 * moment it was struck and a hundred dinars bought a share that rounded to noise in every split
 * plus a partner to answer to at closing. A pool recomputes ownership every period from capital, so
 * a small holding is simply a small holding — and topping up a pool somebody is already in was
 * never floored even under the old rules.
 */
class StoreCapitalRequestRequest extends FormRequest
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
            'investor_id' => ['required', 'integer', 'exists:investors,id'],
            'direction' => ['required', Rule::enum(CapitalRequestDirection::class)],
            // Two decimals, matching the column and every other amount in this ledger.
            'amount' => ['required', 'numeric', 'gt:0', 'max:999999999999'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'investor_id.required' => 'اختر المستثمر',
            'investor_id.exists' => 'المستثمر غير موجود',
            'direction.required' => 'حدّد إدخال رأس مال أم سحبه',
            'amount.required' => 'اكتب المبلغ',
            'amount.gt' => 'المبلغ يجب أن يكون أكبر من صفر',
        ];
    }
}
