<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Customer;

use App\Domain\Customer\Models\Customer;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Exists;

/**
 * Same shape as creating, plus an optional `shops.*.id` so an existing shop can be edited in
 * place instead of being replaced.
 *
 * The rules are written out in full rather than merged onto the parent's on purpose: Scramble
 * reads this method statically to build the OpenAPI request body, and it cannot follow a
 * `array_merge(parent::rules(), …)` call — doing that left this endpoint with no documented
 * body at all.
 */
class UpdateCustomerRequest extends StoreCustomerRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'min:2', 'max:255'],
            // Digits only, wide enough for both Libyan mobiles (0912345678) and
            // landlines (0213334444).
            'primary_phone' => ['required', 'string', 'regex:/^\d{9,15}$/'],
            // Omit to leave the customer's current state alone.
            'is_active' => ['sometimes', 'boolean'],

            // Omit `shops` to keep the existing ones. Sending the key replaces the whole set:
            // entries with an `id` are updated, entries without one are added, and anything
            // left out is deleted.
            'shops' => ['sometimes', 'array'],
            'shops.*.id' => ['sometimes', 'integer', $this->shopBelongsToThisCustomer()],
            'shops.*.name' => ['required', 'string', 'max:255'],
            'shops.*.location' => ['required', 'string', 'max:255'],
            'shops.*.page_url' => ['nullable', 'url', 'max:2048'],
        ];
    }

    /**
     * Restricts a supplied shop id to this customer's own shops, so one customer's request
     * can never reach into another's data.
     */
    private function shopBelongsToThisCustomer(): Exists
    {
        /** @var Customer $customer */
        $customer = $this->route('customer');

        return Rule::exists('customer_shops', 'id')->where('customer_id', $customer->getKey());
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return array_merge(parent::messages(), [
            'shops.*.id.exists' => 'المحل المحدد لا ينتمي لهذا العميل',
        ]);
    }
}
