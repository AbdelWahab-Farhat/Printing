<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

use App\Domain\Delivery\Enums\FulfilmentType;

/**
 * The texts staff copy and send to a customer on WhatsApp — four of them, and which one an order
 * gets is decided here.
 *
 * Each has a built-in wording ({@see defaultBody()}) and an optional override the admin types on
 * «رسائل الزبائن» in the settings, stored in {@see settingColumn()} on `company_settings`. Null
 * there means the built-in text. See Docs/orders/ORDER-RETURN-MESSAGE.md §٥.
 *
 * **One placeholder, {@see INVOICE_PLACEHOLDER}**, replaced with the order's code. A text without
 * it is allowed: the admin may prefer a message that does not quote the number.
 */
enum CustomerMessage: string
{
    /** Dispatched for office pickup — «استلام مكتب». */
    case ReadyPickup = 'ready_pickup';

    /** Dispatched for delivery — «جاري التوصيل». */
    case ReadyDelivery = 'ready_delivery';

    /** «راجع لدى المندوب». */
    case ReturnCourier = 'return_courier';

    /** «راجع لدى شركة التوصيل». */
    case ReturnCarrier = 'return_carrier';

    public const INVOICE_PLACEHOLDER = '{رقم_الفاتورة}';

    /** The ready text for the way the order left: one for pickup, one for delivery. */
    public static function forReady(FulfilmentType $fulfilment): self
    {
        return $fulfilment->isOfficePickup() ? self::ReadyPickup : self::ReadyDelivery;
    }

    /**
     * The return text for the status the order stands in, or null when it is not a return that
     * asks for a message.
     *
     * **This is the definition of «a return that asks for a message».** `Order::returnMessageApplies()`,
     * the queue filter and the clearing in `ChangeOrderStatus` all read it, so the three can
     * never disagree about which statuses count. «راجع مكتب» is absent on purpose: the parcel
     * is back on our shelf and the next step is ours, not the customer's.
     */
    public static function forReturn(OrderStatus $status): ?self
    {
        return match ($status) {
            OrderStatus::ReturnedCourier => self::ReturnCourier,
            OrderStatus::ReturnedCarrier => self::ReturnCarrier,
            default => null,
        };
    }

    /**
     * The statuses {@see forReturn()} answers for, as stored values — for SQL.
     *
     * @return list<string>
     */
    public static function returnStatusValues(): array
    {
        return array_values(array_map(
            fn (OrderStatus $status) => $status->value,
            array_filter(OrderStatus::cases(), fn (OrderStatus $status) => self::forReturn($status) !== null),
        ));
    }

    /** The column on `company_settings` that holds the admin's wording. */
    public function settingColumn(): string
    {
        return $this->value.'_message';
    }

    /** What the settings screen calls it. */
    public function label(): string
    {
        return match ($this) {
            self::ReadyPickup => 'رسالة الجاهزية — استلام مكتب',
            self::ReadyDelivery => 'رسالة الجاهزية — توصيل',
            self::ReturnCourier => 'رسالة الراجع — راجع لدى المندوب',
            self::ReturnCarrier => 'رسالة الراجع — راجع لدى شركة التوصيل',
        };
    }

    /**
     * The built-in wording, used whenever the admin has not typed one.
     *
     * The two ready texts are the owner's own (2026-10-28, 2026-11-10), moved here from the app
     * unchanged; the two return texts were approved on 2026-11-14.
     */
    public function defaultBody(): string
    {
        $invoice = self::INVOICE_PLACEHOLDER;

        return implode("\n\n", match ($this) {
            self::ReadyPickup => [
                'أهلا وسهلا بيك ، يومك طيب إن شاء الله',
                "طلبيتك رقم الفاتورة : [ {$invoice} ] جاهزة للاستلام من مكتب شركة بريمولا .",
                'ساعات الدوام من الساعة 10 صباحا حتى 10 مساء .',
            ],
            self::ReadyDelivery => [
                'أهلا وسهلا بيك ، يومك طيب إن شاء الله',
                "طلبيتك رقم الفاتورة : [ {$invoice} ] في الطريق إليك مع مندوب التوصيل .",
            ],
            self::ReturnCourier => [
                'أهلا وسهلا بيك ، يومك طيب إن شاء الله',
                "مندوب التوصيل حاول يوصلك طلبيتك رقم الفاتورة : [ {$invoice} ] ولم يتم الاستلام .",
                'شن المشكلة اللي واجهتك ؟ طمنا باش نرتبوا معاك وقت توصيل يناسبك .',
            ],
            self::ReturnCarrier => [
                'أهلا وسهلا بيك ، يومك طيب إن شاء الله',
                "طلبيتك رقم الفاتورة : [ {$invoice} ] رجعت لشركة التوصيل لأنها لم تُستلم .",
                'شن المشكلة اللي واجهتك ؟ تحب نعاودوا نرسلوها ليك ، ولا تستلمها من مكتب شركة بريمولا ؟',
            ],
        });
    }
}
