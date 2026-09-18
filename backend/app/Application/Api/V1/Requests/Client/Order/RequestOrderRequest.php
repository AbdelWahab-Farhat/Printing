<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Order;

use App\Domain\Catalog\Models\Product;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

/**
 * A customer placing an order from the app.
 *
 * **Deliberately not an extension of `StoreOrderRequest`.** The design-and-catalogue requests
 * next door were worth inheriting because what they carry is a security decision that must exist
 * once — which file types we accept, which magic bytes. This one is the opposite: what it
 * carries is the *list of fields a customer may send*, and inheriting would mean that list grows
 * silently every time a staff field is added. A separate, shorter list is the point.
 *
 * What is refused by absence, and why each one matters:
 *
 * - `customer_id` — taken from the token. A customer who could send one could order for
 *   somebody else and read the result back.
 * - `items.*.unit_price` — the server prices every line through `CatalogService::quote()`. A
 *   client that could post a price could buy at a price it invented.
 * - `discount`, `additional_cost` — behind `orders.discount` and `orders.additional_cost`, which
 *   a customer does not hold and cannot be given.
 * - `vendor_id` — the customer does not know we outsource anything, and it is not their choice.
 *   Named by staff during review; see the acceptance guard in `ChangeOrderStatus`.
 * - `design_source`, `design_fee` — what the shop charges to draw something is a conversation,
 *   not a field.
 * - `tracking_number`, `is_urgent`, `notes` on the order — operational, staff-written.
 *
 * `design_ids` *is* accepted, and the domain checks each one belongs to this customer — see
 * `AddOrderDesign`. A foreign design takes the whole order down rather than leaving one standing
 * without the file it was placed for.
 */
class RequestOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            // Where it is going. The shop and the region are optional in the same way they are
            // for staff: a customer ordering to a new address has no branch to name.
            'city_id' => ['required', 'integer', Rule::exists('cities', 'id')->withoutTrashed()],
            'region_id' => ['nullable', 'integer', Rule::exists('regions', 'id')->withoutTrashed()],
            'customer_shop_id' => ['nullable', 'integer', Rule::exists('customer_shops', 'id')->withoutTrashed()],

            'recipient_name' => ['nullable', 'string', 'max:255'],
            'recipient_phone' => ['nullable', 'string', 'max:20'],
            'address_details' => ['nullable', 'string', 'max:1000'],

            // The same cap staff have. A hundred distinct lines from a phone is a mistake, and
            // the ceiling costs an honest order nothing.
            'items' => ['required', 'array', 'min:1', 'max:100'],
            // **Live products only**, which `withoutTrashed()` alone does not say: a product is
            // deactivated rather than deleted so past orders keep pointing at a row that still
            // exists, and without `is_active` the catalogue could stop listing something while
            // the order endpoint went on accepting it by id.
            'items.*.product_id' => [
                'required',
                'integer',
                Rule::exists('products', 'id')->where('is_active', true)->withoutTrashed(),
            ],
            'items.*.product_variant_id' => ['required', 'integer', Rule::exists('product_variants', 'id')->withoutTrashed()],

            // **`decimal:0,3` and not `numeric` alone.** `numeric` is `is_numeric()`, which
            // accepts `1e5` — and that string reaches `bccomp()` in
            // {@see Product::meetsMinimumOrder()} unchanged, where bcmath throws rather than
            // compares. Three places is what the column stores; more was being silently rounded.
            'items.*.quantity' => ['required', 'numeric', 'decimal:0,3', 'min:0.001', 'max:999999999'],

            // Chosen from the customer's own library, never uploaded here — the rule the staff
            // endpoint follows and the reason the designs feature exists at all.
            'design_ids' => ['sometimes', 'array', 'max:50'],
            'design_ids.*' => ['integer', Rule::exists('customer_designs', 'id')->withoutTrashed()],

            // What the customer wants to say about the order. A separate field from the order's
            // `notes`, which is staff-written — see `prepareForValidation()`.
            'customer_note' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * The one rule that needs the catalogue in hand rather than the request alone.
     *
     * **Half a shipping bag is not a thing.** `QuoteProductRequest` has said so since the quote
     * endpoint was written, `PricingUnit::requiresWholeQuantities()` says so in its own docblock,
     * and `SalesStatisticsQuery` leans on it. Only the endpoint that actually *places* the order
     * never asked, so a basket priced by the piece could be sent with 2.5 in it.
     *
     * Reported against `items.N.quantity` rather than a bare `quantity`, because a basket has
     * several lines and a customer cannot act on a message that does not say which one.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $items = $this->input('items');

            if (! is_array($items)) {
                return;
            }

            // One query for the whole basket, not one per line.
            $products = Product::query()
                ->whereIn('id', array_filter(array_column($items, 'product_id')))
                ->get()
                ->keyBy('id');

            foreach ($items as $index => $item) {
                if (! is_array($item)) {
                    continue;
                }

                $quantity = $item['quantity'] ?? null;
                $product = $products->get((int) ($item['product_id'] ?? 0));

                // A missing product or an unusable quantity is already somebody else's error;
                // adding a second one about the same field would only bury the first.
                if ($product === null || ! is_numeric($quantity)) {
                    continue;
                }

                if (! $product->pricing_unit->requiresWholeQuantities()) {
                    continue;
                }

                if (floor((float) $quantity) !== (float) $quantity) {
                    $validator->errors()->add(
                        "items.{$index}.quantity",
                        'الكمية يجب أن تكون رقماً صحيحاً للمنتجات المُسعَّرة بالقطعة',
                    );
                }
            }
        });
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'city_id.required' => 'مدينة التوصيل مطلوبة',
            'city_id.exists' => 'المدينة غير موجودة',
            'region_id.exists' => 'المنطقة غير موجودة',
            'items.required' => 'أضف منتجاً واحداً على الأقل',
            'items.min' => 'أضف منتجاً واحداً على الأقل',
            'items.*.product_id.required' => 'المنتج مطلوب',
            'items.*.product_variant_id.required' => 'المقاس مطلوب',
            'items.*.product_id.exists' => 'المنتج غير متاح للطلب',
            'items.*.quantity.required' => 'الكمية مطلوبة',
            'items.*.quantity.numeric' => 'الكمية يجب أن تكون رقماً',
            'items.*.quantity.decimal' => 'الكمية يجب أن تكون رقماً بثلاث خانات عشرية على الأكثر',
            'items.*.quantity.min' => 'الكمية يجب أن تكون أكبر من صفر',
            'design_ids.*.exists' => 'التصميم غير موجود',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'city_id' => 'المدينة',
            'region_id' => 'المنطقة',
            'items' => 'المنتجات',
            'customer_note' => 'ملاحظاتك',
        ];
    }
}
