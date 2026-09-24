<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Actions\UndoOrderDelivery;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Undoing a delivery.
 *
 * **One field, required** — it takes back the profit the delivery credited to investors, which is
 * the bar `UnsettleOrderRequest` sets. There is no destination to send: it is read from the
 * order's timeline — see {@see UndoOrderDelivery}. The permission is on the route.
 */
class UndoOrderDeliveryRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['reason' => 'السبب'];
    }
}
