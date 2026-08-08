<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Enums;

/**
 * Where a purchase order is, and the only moves it may make from there.
 *
 * **This enum is the state machine**, the same role {@see OrderStatus} plays for orders, sized
 * down to what a purchase order actually needs. The map in {@see allowedNext()} is the single
 * definition of what is legal; both the manual status endpoint and
 * {@see ReceivePurchaseOrder} answer to it.
 *
 * **`Arrived` deliberately covers two things a bigger machine might split**: "sent to the
 * vendor, nothing has shown up yet" and "some of it has arrived, some hasn't". A purchase order
 * moves into it either by a deliberate "mark as sent" (`PATCH .../status`) or automatically the
 * moment the first shipment posts against it — whichever happens first. Splitting those into a
 * `sent` and a `partially_received` case would ask a client to tell two states apart that no one
 * here needs told apart: both mean "this order is in motion, not everything is on the shelf yet".
 *
 * `Completed` is reachable only from stock actually arriving, never as a manual target — see
 * `ChangePurchaseOrderStatusRequest`. A purchase order is done when {@see ReceivePurchaseOrder}
 * says every line is fully received, not when someone declares it so.
 */
enum PurchaseOrderStatus: string
{
    /** Just created. The only status a purchase order may still be edited in. */
    case New = 'new';

    /** In motion — sent, awaiting the vendor, or partway received. See the class docblock. */
    case Arrived = 'arrived';

    /** Every line fully received. The end of the road. */
    case Completed = 'completed';

    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::New => 'جديد',
            self::Arrived => 'قيد الاستلام',
            self::Completed => 'مكتمل',
            self::Cancelled => 'ملغى',
        };
    }

    /**
     * Every move this status may make.
     *
     * @return list<self>
     */
    public function allowedNext(): array
    {
        return match ($this) {
            self::New => [self::Arrived, self::Cancelled],
            self::Arrived => [self::Completed, self::Cancelled],
            self::Completed, self::Cancelled => [],
        };
    }

    public function canMoveTo(self $target): bool
    {
        return in_array($target, $this->allowedNext(), true);
    }

    /** Finished. Nothing follows, and nothing may reopen it. */
    public function isFinal(): bool
    {
        return $this === self::Completed || $this === self::Cancelled;
    }

    /** Whether the order's fields and lines may still be changed with `PUT`. */
    public function isEditable(): bool
    {
        return $this === self::New;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $status) => $status->value, self::cases());
    }
}
