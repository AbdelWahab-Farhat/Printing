<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Domain\Order\DTOs\BasketLineQuote;
use App\Domain\Order\DTOs\BasketQuote;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * السلة مسعّرةً كما تعرضها: سعر كل سطرٍ ووحدته، ومجموع البضاعة، ورسم التوصيل، والتكلفة النهائية.
 *
 * **سعرُ البيع وحده.** ما تكلّفه البضاعة علينا وهوامشها في مورد الموظفين ولا تغادره، واختبارٌ يثبت
 * أن السطر لا يحمل غير ما هنا.
 *
 * **و`total_with_delivery` ليس `total` الطلبية.** إجمالي الطلبية البضاعة وحدها — رسم المندوب يُدفع
 * له عند الباب لا لنا — أما السلة فتعرض ما يدفعه العميل في النهاية، فتجمعهما، والاسم يقول ذلك.
 *
 * @mixin BasketQuote
 */
class ClientBasketQuoteResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var BasketQuote $quote */
        $quote = $this->resource;

        return [
            'lines' => array_map(fn (BasketLineQuote $line): array => [
                'product_id' => $line->productId,
                'product_variant_id' => $line->productVariantId,
                // القيمة للمنطق والكلمة للعرض، فلا يحفظ التطبيق جدول ترجمةٍ لوحدات المتجر.
                'unit' => $line->unit->value,
                'unit_label' => $line->unit->label(),
                'unit_price' => $line->unitPrice,
                'line_total' => $line->lineTotal,
            ], $quote->lines),
            'items_total' => $quote->itemsTotal,
            'delivery_price' => $quote->deliveryPrice,
            'total_with_delivery' => $quote->totalWithDelivery,
        ];
    }
}
