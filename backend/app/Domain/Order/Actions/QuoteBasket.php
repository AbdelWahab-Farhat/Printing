<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Catalog\CatalogService;
use App\Domain\Catalog\Exceptions\QuantityBelowMinimum;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Delivery\DeliveryService;
use App\Domain\Order\DTOs\BasketLineQuote;
use App\Domain\Order\DTOs\BasketQuote;
use App\Domain\Order\DTOs\OrderItemData;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\Money;

/**
 * يسعّر سلةً كما ستُسعَّر الطلبية حين تُرسل — ولا يكتب شيئاً.
 *
 * **الطريق نفسه، لا حسابٌ ثانٍ.** كلُّ سطرٍ يمرّ بما يمرّ به في {@see AddOrderItem}: الحدّ الأدنى
 * أولاً، ثم `CatalogService::quote()` لمنتجٍ له أسعار، ثم {@see OrderItem::deriveLineTotal()} على
 * سطرٍ غير محفوظ — القاعدة الوحيدة لأيّ كميةٍ تُفوتَر وكيف تُقرَّب. ومجموع السطور بـ
 * {@see Money::sum()} كما يجمعها {@see RecalculateOrderTotals}. حسابٌ كُتب مرتين يفترق يوماً،
 * و`ClientBasketQuoteTest` يثبت أن هذا لم يفترق.
 *
 * **والتوصيل يُضاف هنا وحده.** رسم المندوب خارج إجمالي الطلبية بقرار صاحب العمل — يُدفع له عند
 * الباب — لكنه مالٌ يخرج من جيب العميل، و«التكلفة النهائية» في السلة تجمعهما.
 */
final class QuoteBasket
{
    public function __construct(
        private readonly CatalogService $catalog,
        private readonly DeliveryService $delivery,
    ) {}

    /**
     * @param  list<OrderItemData>  $items
     *
     * @throws QuantityBelowMinimum
     */
    public function __invoke(array $items, ?int $cityId): BasketQuote
    {
        $lines = array_map(fn (OrderItemData $item) => $this->line($item), $items);

        $totals = array_map(fn (BasketLineQuote $line) => $line->lineTotal, $lines);
        $itemsTotal = in_array(null, $totals, true) ? null : Money::sum(...$totals);

        $deliveryPrice = $this->deliveryPrice($cityId);

        return new BasketQuote(
            lines: $lines,
            itemsTotal: $itemsTotal,
            deliveryPrice: $deliveryPrice,
            totalWithDelivery: $itemsTotal !== null && $deliveryPrice !== null
                ? Money::sum($itemsTotal, $deliveryPrice)
                : null,
        );
    }

    /**
     * @throws QuantityBelowMinimum
     */
    private function line(OrderItemData $item): BasketLineQuote
    {
        $product = $this->catalog->findProduct($item->productId);

        /** @var ProductVariant $variant */
        $variant = $product->variants->firstWhere('id', $item->productVariantId)
            ?? $product->variants()->with('priceTiers')->findOrFail($item->productVariantId);

        // الحدّ الأدنى قبل التسعير كما في `AddOrderItem`: قاعدة الكتالوج لا قاعدة قائمة الأسعار،
        // فتلزم منتجات «حسب الطلب» أيضاً.
        if (! $product->meetsMinimumOrder($item->quantity)) {
            throw QuantityBelowMinimum::make(
                $item->quantity,
                (string) $product->min_order_quantity,
                $product->pricing_unit,
                $product->name,
            );
        }

        $unitPrice = $product->hasListedPrices()
            ? $this->catalog->quote($product, $variant, $item->quantity)->unitPrice
            : null;

        // سطرٌ لا يُحفظ، ليُشتقّ مجموعه من القاعدة نفسها التي تشتقّه للطلبية.
        $draft = (new OrderItem)->forceFill([
            'quantity' => $item->quantity,
            'unit_price' => $unitPrice,
        ]);

        return new BasketLineQuote(
            productId: (int) $product->getKey(),
            productVariantId: (int) $variant->getKey(),
            unit: $product->pricing_unit,
            unitPrice: $unitPrice,
            lineTotal: $draft->deriveLineTotal(),
        );
    }

    /**
     * `null` بلا مدينة، أو لمدينةٍ لم يُتّفق على سعر توصيلها بعد — وذلك «يُحدَّد عند المراجعة» لا
     * «مجاناً». الاستلام من المكتب سعره المسجّل صفر، وهو جوابٌ معروف.
     */
    private function deliveryPrice(?int $cityId): ?string
    {
        if ($cityId === null) {
            return null;
        }

        $city = $this->delivery->findCity($cityId);

        return $city->hasDeliveryPrice() ? (string) $city->delivery_price : null;
    }
}
