<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Enums\ManufacturingCostType;
use App\Domain\Order\Models\ManufacturingCostRate;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * A new standard rate for one cost type — either specific to a product, or, with `product_id`
 * left out, the fallback every product without its own rate is costed at.
 */
class StoreManufacturingCostRateRequest extends FormRequest
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
            // Omitted entirely, not merely blank, is what makes this the default rate — see the
            // model's docblock.
            'product_id' => [
                'nullable', 'integer',
                Rule::exists('products', 'id')->whereNull('deleted_at'),
            ],

            // The uniqueness check lives here, not on `product_id`: `nullable` stops Laravel
            // validating every later rule on a field once its value is empty, and the commonest
            // case this must catch — a second *default* rate, with no product_id sent at all —
            // is exactly that. `cost_type` is `required`, so it is validated unconditionally.
            'cost_type' => ['required', Rule::enum(ManufacturingCostType::class), $this->uniquePerCostType()],

            'rate_per_unit' => ['required', 'numeric', 'gte:0', 'max:999999999.999'],

            'is_active' => ['sometimes', 'boolean'],

            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * One row per (product, cost type), and one default per cost type — the same pair of partial
     * indexes the migration enforces underneath this.
     */
    protected function uniquePerCostType(): \Closure
    {
        return function (string $attribute, mixed $value, \Closure $fail): void {
            $costType = (string) $value;
            $raw = $this->input('product_id');
            $productId = $raw !== null && $raw !== '' ? (int) $raw : null;

            $exists = ManufacturingCostRate::query()
                ->where('cost_type', $costType)
                ->when(
                    $productId === null,
                    fn ($query) => $query->whereNull('product_id'),
                    fn ($query) => $query->where('product_id', $productId),
                )
                ->when(
                    $this->routeHasRate(),
                    fn ($query) => $query->whereKeyNot($this->route('manufacturing_cost_rate')->getKey()),
                )
                ->exists();

            if ($exists) {
                $fail($productId === null
                    ? 'يوجد بالفعل معدل افتراضي لهذا النوع من التكاليف'
                    : 'يوجد بالفعل معدل لهذا المنتج ولهذا النوع من التكاليف');
            }
        };
    }

    private function routeHasRate(): bool
    {
        return $this->route('manufacturing_cost_rate') instanceof ManufacturingCostRate;
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'product_id.exists' => 'المنتج المحدد غير موجود',
            'cost_type.required' => 'نوع التكلفة مطلوب',
            'cost_type.enum' => 'نوع التكلفة غير صحيح',
            'rate_per_unit.required' => 'المعدل مطلوب',
            'rate_per_unit.numeric' => 'المعدل يجب أن يكون رقماً',
            'rate_per_unit.gte' => 'المعدل يجب ألا يكون سالباً',
            'rate_per_unit.max' => 'المعدل أكبر من الحد المسموح',
            'is_active.boolean' => 'الحالة يجب أن تكون صحيحة أو خاطئة',
            'notes.max' => 'الملاحظات طويلة جداً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'product_id' => 'المنتج',
            'cost_type' => 'نوع التكلفة',
            'rate_per_unit' => 'المعدل',
            'is_active' => 'الحالة',
            'notes' => 'الملاحظات',
        ];
    }
}
