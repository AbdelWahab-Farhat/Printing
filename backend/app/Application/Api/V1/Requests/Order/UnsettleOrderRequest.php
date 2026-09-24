<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Actions\UnsettleOrder;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Undoing a settlement.
 *
 * **One field, and it is required** — where a reinstatement's is optional. Reopening an order the
 * books treated as closed is the bar `ReverseOrderPayment` sets for an explanation, not a stray
 * tap. There is no destination to send; see {@see UnsettleOrder}.
 *
 * The permission is on the route, as the reinstatement's is: it does not vary with the body.
 */
class UnsettleOrderRequest extends FormRequest
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
