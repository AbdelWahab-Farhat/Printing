<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Catalog\Enums\PricingUnit;

/**
 * سطرٌ من السلة كما سيُسعَّر في الطلبية.
 */
final readonly class BasketLineQuote
{
    public function __construct(
        public int $productId,
        public int $productVariantId,
        /** بأيّ وحدةٍ تُحسب الكمية — القطعة أو الكيلو. */
        public PricingUnit $unit,
        /** `null` لمنتجٍ «حسب الطلب»: يُسعّره المتجر حين يقبل الطلبية. */
        public ?string $unitPrice,
        public ?string $lineTotal,
        /** يصنعه وسيط — فالطلبية تحتاج مراجعةً يُسمّى فيها، ولا عربونَ في السلة. لا يغادر الخادم. */
        public bool $outsourced = false,
    ) {}
}
