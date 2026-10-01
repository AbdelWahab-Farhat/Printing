<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Carrier;

use App\Domain\Carrier\Actions\DispatchToNawris;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Several orders going to Nawris as one parcel.
 *
 * **Only the ids.** Where it goes, who receives it and what it collects are all read from the
 * orders themselves — see {@see DispatchToNawris::group()} — so there is nothing else here for a
 * caller to name. Whether the orders may share a parcel at all (one customer, one door, one phone)
 * is the domain's rule and answered there, with the order that broke it named.
 */
class StoreSharedParcelRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            // Two at least — one order is what «إرسال للنورس» on the order screen is for. The
            // ceiling is a sanity bound on one request, not a business rule about parcels.
            'order_ids' => ['required', 'array', 'min:2', 'max:50'],
            'order_ids.*' => ['required', 'integer', 'distinct', Rule::exists('orders', 'id')->withoutTrashed()],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'order_ids.min' => 'الطرد المشترك يحتاج طلبيتين على الأقل',
            'order_ids.*.distinct' => 'الطلبية مكررة في الطرد نفسه',
            'order_ids.*.exists' => 'الطلبية غير موجودة',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'order_ids' => 'الطلبيات',
            'order_ids.*' => 'الطلبية',
        ];
    }

    /**
     * @return list<int>
     */
    public function orderIds(): array
    {
        return array_values(array_map(intval(...), (array) $this->validated('order_ids')));
    }
}
