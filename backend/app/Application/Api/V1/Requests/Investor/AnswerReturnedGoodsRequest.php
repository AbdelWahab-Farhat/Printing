<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * «صالحة» أو «تالفة».
 *
 * **`open` is not an answer**, so it is not accepted here. It is the state a question starts in, and
 * a payload that could set it back would let somebody reopen a verdict whose write-off the shelf has
 * already been counted against.
 *
 * **The warehouse is required for both verdicts**, though only «تالفة» writes a movement. Asking for
 * it once, up front, keeps the client from having to know which answer needs it — and the shelf the
 * goods came back to is a fact the person answering is looking at either way.
 *
 * No quantity and no cost. Both were read off the credit-back when the question was raised, and a
 * payload that could restate them would let the amount written off drift from the amount that
 * actually came back.
 */
class AnswerReturnedGoodsRequest extends FormRequest
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
            'verdict' => [
                'required',
                Rule::enum(ReturnedGoodsVerdict::class)->except(ReturnedGoodsVerdict::Open),
            ],
            'warehouse_id' => ['required', 'integer', 'exists:warehouses,id'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'verdict.required' => 'حدّد إن كانت البضاعة صالحة أم تالفة',
            'verdict.enum' => 'الجواب إمّا «صالحة» أو «تالفة»',
            'warehouse_id.required' => 'اختر المخزن الذي رجعت إليه البضاعة',
            'warehouse_id.exists' => 'المخزن غير موجود',
        ];
    }
}
