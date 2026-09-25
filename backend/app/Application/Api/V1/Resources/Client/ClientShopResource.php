<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Application\Api\V1\Resources\CustomerShopResource;
use App\Domain\Customer\Models\CustomerShop;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * متجرٌ من متاجر العميل، كما يرسمه «متاجري» وصفحة المتجر وخطوةُ «بيانات الطلب» في السلة.
 *
 * **المُعرِّفات للاختيار، والأسماء للرسم.** النموذج يختار المجال والمدينة والمنطقة بمُعرِّفاتها، والشاشة
 * تكتب «بنغازي · الكيش» و«ملابس وأحذية» بلا طلبٍ ثانٍ لخريطة التوصيل ولا لقائمة المجالات. والاسم
 * `null` حين يُخرَج صفّه بعد تسجيل المتجر — المُعرِّف يبقى، والاسم لا يُخترع.
 *
 * **وما لا يُرسل:** الإحداثيات مكانُ أحدٍ على الأرض ولا خريطة في التطبيق، و`customer_id` هو صاحب
 * التوكن نفسه. {@see CustomerShopResource} هو ما يراه الموظفون، ولا يُورَث هنا للسبب الذي لا يرث لأجله
 * أيُّ موردٍ للعميل توأمَه: ما يراه العميل تقرّره هذه القائمة لا صلاحية.
 *
 * @mixin CustomerShop
 */
class ClientShopResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'business_field_id' => $this->business_field_id,
            'business_field_name' => $this->businessField?->name,
            'city_id' => $this->city_id,
            'city_name' => $this->city?->name,
            'region_id' => $this->region_id,
            'region_name' => $this->region?->name,
            'page_url' => $this->page_url,
        ];
    }
}
