<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\DTOs\ManagedOrderLine;
use Illuminate\Foundation\Http\FormRequest;

/**
 * «إدارة الطلبية»: each line's quantity and price, and nothing else.
 *
 * **The price is required**, not optional: the screen opens every line on the price it carries,
 * so whatever arrives is the price the person saving it confirmed. Leaving it out would let a
 * moved quantity price the line from the catalogue behind their back.
 *
 * Whether each id is this order's line, and whether the order's status lets its lines be managed,
 * are asked by ManageOrderLines on the locked row. The grant is on the route.
 */
class ManageOrderLinesRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['required', 'integer', 'distinct'],
            'items.*.quantity' => ['required', 'numeric', 'gt:0', 'decimal:0,3', 'max:999999999'],
            'items.*.unit_price' => ['required', 'numeric', 'min:0', 'max:9999999.999'],
            'items.*.warehouse_quantity' => ['nullable', 'numeric', 'gt:0', 'decimal:0,3', 'max:999999999'],
        ];
    }

    /**
     * @return list<ManagedOrderLine>
     */
    public function lines(): array
    {
        /** @var list<array{id: int|string, quantity: int|float|string, unit_price: int|float|string, warehouse_quantity?: int|float|string|null}> $items */
        $items = $this->validated('items');

        return array_map(
            fn (array $item): ManagedOrderLine => new ManagedOrderLine(
                id: (int) $item['id'],
                quantity: (string) $item['quantity'],
                unitPrice: (string) $item['unit_price'],
                warehouseQuantity: isset($item['warehouse_quantity']) ? (string) $item['warehouse_quantity'] : null,
            ),
            $items,
        );
    }
}
