<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Domain\Order\Enums\CustomerOrderStage;
use App\Domain\Order\Models\OrderStatusTransition;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * ملاحظةٌ على الطلبية كما يقرؤها العميل: عند أيّ مرحلةٍ كُتبت، وما كُتب، ومتى.
 *
 * **بالمرحلة لا بحالة الورشة**، كبقية ما يصل العميل: «رُفض الطلب» تصله «مرفوضة»، بكلمتها
 * ولونها في «طلباتي».
 *
 * **ولا اسم لمن كتبها**، كرسائل الدعم ({@see ClientTicketMessageResource}): من يكتب للعميل هو
 * المتجر، وأيّ زميلٍ راجع الطلبية شأنٌ داخلي.
 *
 * @mixin OrderStatusTransition
 */
class ClientOrderNoteResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $stage = CustomerOrderStage::forStatus($this->to_status);

        return [
            'id' => $this->id,
            'stage' => $stage->value,
            'stage_label' => $stage->label(),
            'text' => trim((string) $this->reason),
            'written_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
