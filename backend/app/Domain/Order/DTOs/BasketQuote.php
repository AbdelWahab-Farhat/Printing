<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Catalog\DTOs\PriceQuote;

/**
 * سلةٌ مسعّرةٌ قبل أن تصير طلبية — «التكلفة النهائية» التي تعرضها السلة.
 *
 * كل مبلغٍ نصٌّ عشري لا `float`، كما في {@see PriceQuote} والطلبية نفسها. و`null` جوابٌ لا نقص:
 * سطرٌ «حسب الطلب» لا سعر له بعد، ومدينةٌ بلا سعرٍ متّفقٍ عليه لا توصيل معروفاً لها — وفي الحالين
 * لا مجموع يُكتب، لأن مجموع المعروف وحده رقمٌ أصغر مما سيُطلب.
 */
final readonly class BasketQuote
{
    /**
     * @param  list<BasketLineQuote>  $lines  بترتيب السلة نفسه.
     */
    public function __construct(
        public array $lines,
        /** مجموع السطور، أو `null` حين ينتظر أحدها تسعيراً. */
        public ?string $itemsTotal,
        /** رسم المندوب إلى المدينة المختارة، أو `null` بلا مدينة أو بلا سعرٍ متّفقٍ عليه. */
        public ?string $deliveryPrice,
        /** البضاعة مع رسم المندوب — ما يدفعه العميل في النهاية — أو `null` إن جُهل أحدهما. */
        public ?string $totalWithDelivery,
    ) {}
}
