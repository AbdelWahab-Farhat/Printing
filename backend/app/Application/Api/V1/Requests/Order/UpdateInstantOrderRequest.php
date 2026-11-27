<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use Closure;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Editing an instant order while it is «جديدة»: the lines, the discount and the notes
 * (INSTANT-ORDERS-PLAN.md §9). The branch and the customer are not in it — they do not change.
 *
 * A line that keeps its `id` is kept; one sent without is new; an existing one left out goes,
 * its stock back on the shelf.
 */
class UpdateInstantOrderRequest extends FormRequest
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
            ...StoreInstantOrderRequest::lineRules(),
            'items.*.id' => ['nullable', 'integer'],
            'discount' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99', $this->wholeDinars()],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    /** Whole dinars — except the figure already on the order, which an edit re-sends unchanged. */
    private function wholeDinars(): Closure
    {
        return function (string $attribute, mixed $value, Closure $fail): void {
            if (! is_numeric($value)) {
                return;
            }

            $amount = Money::normalize($value);
            $order = $this->route('order');

            if (Money::isWhole($amount)
                || ($order instanceof Order && bccomp($amount, (string) $order->discount, Money::SCALE) === 0)) {
                return;
            }

            $fail('الخصم بالدينار الكامل، بلا كسور');
        };
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'items.required' => 'أضف منتجاً واحداً على الأقل',
            'items.min' => 'أضف منتجاً واحداً على الأقل',
            'items.*.quantity.required' => 'الكمية مطلوبة',
            'items.*.quantity.gt' => 'الكمية يجب أن تكون أكبر من صفر',
            'discount.min' => 'الخصم لا يمكن أن يكون سالباً',
        ];
    }
}
