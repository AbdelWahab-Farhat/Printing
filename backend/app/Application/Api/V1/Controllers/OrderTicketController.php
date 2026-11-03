<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Resources\OrderTicketResource;
use App\Application\Controller;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Queries\OrderTicketsQuery;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * «التذاكر المرتبطة» في صفحة الطلبية.
 */
class OrderTicketController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly OrderTicketsQuery $tickets) {}

    /**
     * List the tickets linked to an order
     *
     * تذاكرُ الموظفين والتصميم والعملاء التي تحمل هذه الطلبية، كلٌّ بنوعه، المفتوحةُ أولاً ثم
     * الأحدثُ نشاطاً — المغلقةُ معها، لا تُسقط.
     *
     * **بلا صفحات**: تذاكرُ طلبيةٍ واحدة بضعُ صفوف. وما لا يراه القارئ في قائمة نوعه لا يراه هنا:
     * تذكرةُ زميلين لا تظهر لثالث، وتذاكرُ التصميم والعملاء لا تظهر لمن لا يملك صلاحيةَ قائمتها.
     */
    public function index(Request $request, Order $order): JsonResponse
    {
        return $this->success(OrderTicketResource::collection(($this->tickets)($order, $request->user())));
    }
}
