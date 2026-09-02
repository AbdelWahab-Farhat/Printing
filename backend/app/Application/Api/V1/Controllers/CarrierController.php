<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Resources\NawrisParcelResource;
use App\Application\Api\V1\Resources\NawrisWebhookEventResource;
use App\Application\Api\V1\Resources\OrderResource;
use App\Application\Controller;
use App\Domain\Carrier\CarrierService;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisWebhookEvent;
use App\Domain\Order\Models\Order;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Carrier operations
 *
 * The screens that exist because this integration can fail quietly.
 *
 * **Two queues, and neither is optional.** A webhook that arrived and was never processed is an
 * order that has silently stopped moving; an order dispatched but never lodged is a parcel the
 * carrier has never heard of. Both are invisible without somewhere to look, and both are the
 * failure modes that otherwise go unnoticed for weeks.
 */
class CarrierController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly CarrierService $carrier) {}

    /**
     * Inbound webhooks
     *
     * Newest first. Filter with `pending=1` for events received and never processed, and
     * `unmatched=1` for events that matched no parcel we know about.
     */
    public function events(Request $request): JsonResponse
    {
        $query = NawrisWebhookEvent::query()->latest('id');

        if ($request->boolean('pending')) {
            $query->whereNull('processed_at');
        }

        if ($request->boolean('unmatched')) {
            $query->whereNull('nawris_parcel_id');
        }

        $events = $query->paginate(min((int) $request->integer('per_page', 25), 100));

        return $this->successWithPagination(NawrisWebhookEventResource::collection($events));
    }

    /**
     * Parcels
     *
     * Filter with `open=1` for parcels still out there, and `conflict=1` for those waiting on a
     * human to close a delivery conflict.
     */
    public function parcels(Request $request): JsonResponse
    {
        $query = NawrisParcel::query()->latest('id');

        if ($request->boolean('open')) {
            $query->whereNull('closed_at');
        }

        if ($request->boolean('conflict')) {
            $query->whereNotNull('conflict_raised_at')->whereNull('conflict_resolved_at');
        }

        $parcels = $query->paginate(min((int) $request->integer('per_page', 25), 100));

        return $this->successWithPagination(NawrisParcelResource::collection($parcels));
    }

    /**
     * Orders sent out but never lodged with the carrier
     *
     * The outbound twin of an unprocessed webhook. Nothing is wrong with these orders — they are
     * out for delivery and Nawris has simply never been told — so they are retryable rather than
     * broken.
     */
    public function notLodged(Request $request): JsonResponse
    {
        $orders = $this->carrier->ordersNotLodged()
            ->latest('id')
            ->paginate(min((int) $request->integer('per_page', 25), 100));

        return $this->successWithPagination(OrderResource::collection($orders));
    }

    /**
     * Lodge an order that went out without reaching the carrier
     *
     * Retries the dispatch without touching the order's status: the parcel is already out, and
     * moving it backwards to describe a failed API call would be a lie about a physical thing.
     */
    public function lodge(Order $order): JsonResponse
    {
        $parcel = $this->carrier->dispatchOrder($order);

        return $this->created(new NawrisParcelResource($parcel), 'تم تسليم الشحنة لنورس');
    }

    /**
     * Call off a live shipment
     *
     * **Does not cancel the order.** «إلغاء تام» is unreachable while a parcel is outside the
     * building — the goods still have to come home, and they come home through the return chain.
     */
    public function cancelShipment(Order $order): JsonResponse
    {
        $parcel = $this->carrier->cancelShipmentFor($order);

        return $parcel === null
            ? $this->successMessage('لا توجد شحنة مفتوحة لهذه الطلبية')
            : $this->success(new NawrisParcelResource($parcel), 'تم إلغاء الشحنة لدى نورس');
    }

    /**
     * Close a delivery conflict
     *
     * A conflict is raised automatically and cleared automatically by a clean delivery. This is
     * the third way out: a person looked, and decided.
     */
    public function resolveConflict(NawrisParcel $parcel): JsonResponse
    {
        $parcel->forceFill(['conflict_resolved_at' => now()])->save();

        return $this->success(new NawrisParcelResource($parcel), 'تم إغلاق التعارض');
    }
}
