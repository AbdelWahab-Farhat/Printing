<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\DTOs\CustomerShopData;
use App\Domain\Customer\Models\CustomerShop;

/**
 * يعدّل متجراً كما يعدّله صاحبه من التطبيق: المتجر كاملاً كما يعرضه النموذج.
 *
 * **إلا الإحداثيات.** لا خريطة في التطبيق فلا يرسلها، وغيابها يعني «لم يُرسَل» لا «امسحه» — القاعدة
 * نفسها التي تحفظها {@see SyncCustomerShops}، كي لا يمسح أولُ تعديلٍ من الهاتف دبّوساً سجّله أحدٌ يوم
 * كان النموذج يسأل عنه.
 */
final class UpdateCustomerShop
{
    public function __invoke(CustomerShop $shop, CustomerShopData $data): CustomerShop
    {
        $shop->update([
            'name' => $data->name,
            'business_field_id' => $data->businessFieldId,
            'city_id' => $data->cityId,
            'region_id' => $data->regionId,
            'page_url' => $data->pageUrl,
        ]);

        return $shop;
    }
}
