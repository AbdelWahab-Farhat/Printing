<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\DTOs\CustomerShopData;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerShop;

/**
 * يضيف متجراً إلى متاجر العميل — واحداً، بجانب ما عنده.
 *
 * **ليس {@see SyncCustomerShops}.** تلك تجعل المتاجر مطابقةً لقائمةٍ كاملة يرسلها نموذج الموظفين،
 * فما غاب عنها يُحذف. العميل يضيف متجراً واحداً في كل مرة، ومزامنةٌ هنا كانت ستمسح الباقي.
 *
 * حقول نموذج الموظفين الأربعة، بلا إحداثيات: لا أحد يسأل عنها اليوم.
 */
final class AddCustomerShop
{
    public function __invoke(Customer $customer, CustomerShopData $shop): CustomerShop
    {
        return $customer->shops()->create([
            'name' => $shop->name,
            'business_field_id' => $shop->businessFieldId,
            'city_id' => $shop->cityId,
            'region_id' => $shop->regionId,
            'page_url' => $shop->pageUrl,
        ]);
    }
}
