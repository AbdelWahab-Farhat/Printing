<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Domain\Customer\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * What the customer app is told about its own account.
 *
 * **The first of the client resources, and it sets their one rule: a client resource never asks
 * the gate anything.** The staff resources next door call `$request->user()?->can(...)` to hide
 * costs — see `ProductVariantResource` — and a `Customer` has no `can()` at all, on purpose
 * (`Customer` takes the bare `Authenticatable` contract, not `Authorizable`). So these resources
 * are written as a separate family rather than shared with the staff ones, and what a customer
 * may see is decided by which fields are listed here, not by a permission lookup.
 *
 * Nothing about money, nothing about cost, and no internal note: this is the account, not the
 * file the shop keeps on him.
 *
 * @mixin Customer
 */
class CustomerAccountResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            // «A123» — what staff say on the phone, so the customer should be able to read it
            // back to them.
            'code' => $this->code,
            'name' => $this->name,
            'phone' => $this->phone,
            'is_active' => $this->is_active,

            // **The shop, when the account has one, and never a list of them.** «حسابي» draws one
            // line under a name, and picking which of four shops that line names is a decision
            // the app cannot make. The first is the one the account was opened with.
            //
            // القائمة كلها — وإضافةُ متجرٍ وتعديله وحذفه — في `GET /client/shops`، لا هنا.
            //
            // Loaded rather than queried: `whenLoaded` keeps this resource from firing a query
            // per customer if it is ever used on a list.
            'shop' => $this->whenLoaded('shops', fn (): ?array => $this->firstShop()),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * The shop the account was opened with, named and placed.
     *
     * **ثلاثة حقولٍ ولا مُعرِّف.** هذا سطرٌ في بطاقة «حسابي» لا مِقبضٌ على المتجر: ما يُعدَّل به
     * المتجر يأتي من `GET /client/shops` بمُعرِّفه. وما ترسمه البطاقة «متجر النور · بنغازي» و«ملابس
     * وأحذية»، وذلك بالضبط ما يُرسل.
     *
     * @return array<string, string|null>|null
     */
    protected function firstShop(): ?array
    {
        // بالمُعرِّف لا بترتيب القراءة: العلاقة بلا `orderBy`، وصفٌّ عُدِّل يعود من PostgreSQL بعد غيره.
        $shop = $this->shops->sortBy('id')->first();

        if ($shop === null) {
            return null;
        }

        return [
            'name' => $shop->name,
            'city_name' => $shop->city?->name,
            'business_field' => $shop->businessField?->name,
        ];
    }
}
