<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\Models\CustomerShop;

/**
 * يُخرج متجراً من متاجر العميل.
 *
 * **يُخفى ولا يُمحى.** الطلبيات التي ذهبت إليه تحمل اسمه منسوخاً في `customer_shop_name`، وسجلّ
 * العميل يُظهر من حذفه ومتى — وحذفٌ فعلي كان سيُسقط الاثنين. وطلبيةٌ جديدة لا تستطيع تسميته بعد
 * ذلك، لأن `exists` في طلب الطلبية يتجاهل المحذوف.
 */
final class RemoveCustomerShop
{
    public function __invoke(CustomerShop $shop): void
    {
        $shop->delete();
    }
}
