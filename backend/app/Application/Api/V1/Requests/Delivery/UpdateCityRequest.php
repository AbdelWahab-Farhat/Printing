<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Delivery;

use App\Domain\Delivery\Models\City;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Unique;

/**
 * Same shape as creating; only the uniqueness rule differs, because a city keeping its own name
 * must not collide with itself.
 *
 * The rules are written out in full rather than merged onto the parent's on purpose: Scramble
 * reads this method statically to build the OpenAPI request body and cannot follow an
 * `array_merge(parent::rules(), …)` call — doing that leaves the endpoint with no documented body.
 */
class UpdateCityRequest extends StoreCityRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'min:2', 'max:100', $this->nameUniqueAmongOtherCities()],
            'is_region_required' => ['sometimes', 'boolean'],
            'delivery_price' => ['nullable', 'numeric', 'min:0', 'max:99999999.99'],
            'darb_branch' => ['nullable', 'string', 'max:255'],
            // Sending both as null clears the pin — see StoreCityRequest.
            'latitude' => ['nullable', 'required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'required_with:latitude', 'numeric', 'between:-180,180'],
        ];
    }

    private function nameUniqueAmongOtherCities(): Unique
    {
        /** @var City $city */
        $city = $this->route('city');

        return Rule::unique('cities', 'name')->ignore($city->getKey())->withoutTrashed();
    }
}
