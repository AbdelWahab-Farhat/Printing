<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Shortage;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Saying how much the warehouse is short, in the unit it will be bought in.
 *
 * **Shape only.** Whether this shortage wants a second figure at all is a fact about the stock
 * item behind its size — two relations past the order line — and the domain answers it with its
 * own three sentences rather than a rule here that would have to re-derive them. The same
 * arrangement `RecordShortageSupplyRequest` uses for `warehouse_id`.
 *
 * **No ceiling, deliberately.** The ordered figure is in the *other* unit; measuring a weight
 * against it would be the قطعة→كجم conversion this box exists precisely because nobody can make.
 */
class SetShortageWarehouseQuantityRequest extends FormRequest
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
            'quantity' => ['required', 'numeric', 'gt:0', 'decimal:0,3'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'quantity.required' => 'الكمية الناقصة من المخزن مطلوبة',
            'quantity.gt' => 'الكمية يجب أن تكون أكبر من صفر',
            'quantity.decimal' => 'الكمية تقبل ثلاث خانات عشرية على الأكثر',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['quantity' => 'الكمية الناقصة من المخزن'];
    }
}
