<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\DTOs\LineShortage;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Collection;

/**
 * Correcting what is missing from an order.
 *
 * **Every bound is a fact about this order**, so they are built from its own lines rather than
 * declared as a constant: an id belonging to somebody else's order is refused, and a shortage
 * larger than what was ordered of that size is refused with the number it exceeded. Both are
 * things only the order can answer, and neither may be left to the client that typed them.
 *
 * **A line carries two numbers, and only one of them has a ceiling.** `quantity` is what comes off
 * the invoice, so it cannot exceed what was ordered. `warehouse_quantity` is what the warehouse is
 * short in the unit the shelf counts — there is no ordered figure in that unit to measure it
 * against, and inventing one would mean the قطعة→كجم conversion this system deliberately refuses
 * to make. It is bounded only by being a positive number.
 *
 * **The second is never required here.** A shortage is declared before the goods that would
 * answer it exist, so nobody can weigh them; the field is offered where the shelf disagrees with
 * the invoice and left open when it cannot be filled. What the gap blocks is recording an
 * *arrival* against it — `ShortageWeightIsUnknown` — not declaring the shortage in the first
 * place.
 *
 * The permission is on the route — unlike a status change, this endpoint costs the same grant
 * whatever it is asked to do.
 */
class SetOrderShortagesRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        // Required rather than optional, and an empty object is a legitimate value meaning
        // «لا نقص في شيء»: the set is replaced wholesale, so «send nothing» has to be sayable.
        $rules = ['shortages' => ['required', 'array']];

        foreach ($this->lines() as $item) {
            $key = "shortages.{$item->getKey()}";

            /*
             * **Both shapes are accepted, and that is not laziness.** A bare number is «ناقص
             * ثلاثون» on a line the warehouse counts the way the customer was billed — which is
             * most lines, and the shape every client sent before this column existed. An object
             * is the pair. Refusing the scalar would break every caller for the sake of the
             * minority of sizes that need two numbers.
             */
            $rules[$key] = ['nullable'];
            $rules["{$key}.quantity"] = ['nullable', 'numeric', 'min:0', 'max:'.$item->quantity];
            $rules["{$key}.warehouse_quantity"] = ['nullable', 'numeric', 'gt:0', 'decimal:0,3'];

            $rules[$key][] = function (string $attribute, mixed $value, Closure $fail) use ($item): void {
                if ($value === null || $value === '' || is_array($value)) {
                    return;
                }

                // A scalar is the invoice's number, so it meets the invoice's ceiling.
                if (! is_numeric($value)) {
                    $fail("الناقص من «{$item->variant_label}» يجب أن يكون رقماً");

                    return;
                }

                if (bccomp((string) $value, (string) $item->quantity, 3) > 0) {
                    $fail("الناقص من «{$item->variant_label}» أكبر مما في الطلبية ({$item->quantity})");
                }
            };

            /*
             * **The weight is refused where the units agree, and merely invited where they part.**
             *
             * **Not demanded, and that is the whole point.** The bags are missing — that is what
             * «ناقص» means — so at the moment somebody declares one there is nothing on a scale
             * to read and no factor in the catalogue to derive a weight from. Insisting here
             * would make the form ask for a measurement of goods that do not exist, and the only
             * answer anybody could give is a guess entered under protest.
             *
             * It is left open instead, and whoever first knows fills it in: someone estimating
             * later, or the buyer standing at the supplier. Until then the shortage is counted in
             * the unit it was sold in and no arrival may be recorded against it — see
             * `OrderItem::shortageWeightIsUnknown()` and `ShortageWeightIsUnknown`, which is
             * where the insistence actually belongs.
             *
             * Refused in the other direction for the reason a warehouse on an unstockable
             * shortage is: the caller believes a conversion is happening that is not.
             */
            $rules[$key][] = function (string $attribute, mixed $value, Closure $fail) use ($item): void {
                $weighed = is_array($value) ? ($value['warehouse_quantity'] ?? null) : null;
                $missing = is_array($value) ? ($value['quantity'] ?? null) : $value;

                if ($missing === null || $missing === '' || (string) $missing === '0') {
                    return;
                }

                if ($item->isStockedInAnotherUnit() || $weighed === null || $weighed === '') {
                    return;
                }

                $fail(
                    "«{$item->variant_label}» يُحسب في المخزن بـ«{$item->pricing_unit->label()}» نفسها"
                    .' — لا تُدخل كمية مخزن مختلفة'
                );
            };
        }

        // Anything left over names a line this order does not have. Dropping it silently would
        // report success for a correction that went nowhere.
        $rules['shortages'][] = function (string $attribute, mixed $value, Closure $fail): void {
            $known = $this->lines()->map(fn (OrderItem $item) => (string) $item->getKey())->all();
            $extra = array_diff(array_map('strval', array_keys((array) $value)), $known);

            if ($extra !== []) {
                $fail('هذه البنود ليست في هذه الطلبية: '.implode('، ', $extra));
            }
        };

        return $rules;
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        $messages = [
            'shortages.required' => 'النواقص مطلوبة',
            'shortages.array' => 'النواقص تُرسَل بند بند',
        ];

        foreach ($this->lines() as $item) {
            $key = "shortages.{$item->getKey()}";

            $messages["{$key}.quantity.max"] =
                "الناقص من «{$item->variant_label}» أكبر مما في الطلبية ({$item->quantity})";
            $messages["{$key}.quantity.numeric"] =
                "الناقص من «{$item->variant_label}» يجب أن يكون رقماً";
            $messages["{$key}.warehouse_quantity.gt"] =
                "الكمية الناقصة من المخزن لـ«{$item->variant_label}» يجب أن تكون أكبر من صفر";
            $messages["{$key}.warehouse_quantity.decimal"] =
                'الكمية الناقصة من المخزن تقبل ثلاث خانات عشرية على الأكثر';
        }

        return $messages;
    }

    /**
     * The payload as the domain takes it — one {@see LineShortage} per line named.
     *
     * **Here rather than in the controller**, so the scalar-or-object shape the rules allow is
     * flattened in the same class that permitted it, and nothing downstream has to know the wire
     * ever had two forms.
     *
     * @return array<int, LineShortage>
     */
    public function shortages(): array
    {
        $shortages = [];

        foreach ((array) $this->validated('shortages', []) as $lineId => $value) {
            if ($value === null || $value === '') {
                $shortages[(int) $lineId] = LineShortage::none();

                continue;
            }

            $missing = is_array($value) ? ($value['quantity'] ?? null) : $value;
            $weighed = is_array($value) ? ($value['warehouse_quantity'] ?? null) : null;

            $shortages[(int) $lineId] = $missing === null || $missing === ''
                ? LineShortage::none()
                : new LineShortage(
                    quantity: (string) $missing,
                    warehouseQuantity: $weighed === null || $weighed === '' ? null : (string) $weighed,
                );
        }

        return $shortages;
    }

    /**
     * @return Collection<int, OrderItem>
     */
    private function lines(): Collection
    {
        $order = $this->route('order');

        return $order instanceof Order ? $order->items->load('variant.stockItem') : collect();
    }
}
