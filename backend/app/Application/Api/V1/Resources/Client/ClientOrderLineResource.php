<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Domain\Order\Models\OrderItem;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * سطرٌ واحد من طلبية العميل، بالشكل نفسه في «طلباتي» وفي الطلبية المفتوحة.
 *
 * **شكلٌ واحد في مكانٍ واحد.** كان السطر يُكتب داخل {@see ClientOrderDetailResource} وحده؛ ولما
 * صارت بطاقة القائمة ترسم بنود الطلبية في ذيلها، صار له قارئان — ونسختان منه نسختان تفترقان.
 *
 * ولا كلفة ولا ربح: ما دفعه المتجر في البضاعة يبقى على مورد الموظفين.
 *
 * @mixin OrderItem
 */
class ClientOrderLineResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product_name' => $this->product_name,
            'variant_label' => $this->variant_label,
            'quantity' => (string) $this->quantity,
            // «300» وحدها لا تقول 300 ماذا: كيسٌ يُباع بالقطعة وآخر بالكيلو.
            'pricing_unit_label' => $this->pricing_unit?->label(),
            // **Null, never '0.00'.** A line the shop has not quoted yet has no price, and a zero
            // here would read as «مجاناً» on the customer's screen.
            'unit_price' => $this->unit_price === null ? null : (string) $this->unit_price,
            'line_total' => $this->line_total === null ? null : (string) $this->line_total,

            // **صورة المنتج كما هي في الكتالوج اليوم، لا من لقطة البند** — كسطر الطلبية في مورد
            // الموظفين (`OrderItemResource::product_image`): منتجٌ أُعيد تصويره يظهر بوجهه الجديد،
            // والاسم والسعر فوقها يبقيان ما بيع. والصورة الأولى وحدها، فالبند صفٌّ لا معرض.
            //
            // تُرسل حين تُحمَّل العلاقة وحدها — الطلبية المفتوحة تحمّلها، و«طلباتي» لا ترسم صوراً
            // فلا تحمّلها ولا يصلها المفتاح. وnull لمنتجٍ بلا صورة أو محذوف.
            'product_image_url' => $this->whenLoaded(
                'product',
                fn (): ?string => $this->product?->images->first()?->url(),
            ),
        ];
    }
}
