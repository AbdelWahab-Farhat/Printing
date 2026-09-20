<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Signing a pool's position.
 *
 * **No figures.** Not one of the twelve amounts a settlement carries may be typed: every one is
 * walked from the ledger and the cost layers at the moment of signing, and a payload that could
 * carry them would let somebody approve a position the system does not hold — which is precisely
 * the discrepancy the drift exists to catch.
 *
 * **No period range either.** The span is «everything closed since the last settlement», derived,
 * because a caller naming its own range could quietly leave a bad month out of every settlement
 * that ever covered it.
 *
 * What is left is what a person genuinely decides: the date it is being signed as of, who approved
 * it, and what they want to say about it.
 */
class StoreSettlementRequest extends FormRequest
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
            // Back-dating is allowed and forward-dating is not: a settlement is a statement about
            // a position that already exists, and one dated next week asserts nothing.
            'settled_on' => ['nullable', 'date', 'before_or_equal:today'],
            'approved_by' => ['nullable', 'integer', 'exists:users,id'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'settled_on.before_or_equal' => 'لا يمكن تأريخ التسوية في المستقبل',
            'approved_by.exists' => 'المستخدم غير موجود',
        ];
    }
}
