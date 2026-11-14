<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

use App\Domain\Delivery\Enums\FulfilmentType;

/**
 * The texts staff copy and send on WhatsApp — four to the customer and one to the vendor of an
 * outsourced order — and which one an order gets is decided here.
 *
 * Each has a built-in wording ({@see defaultBody()}) and an optional override the admin types on
 * «نصوص الرسائل» in the settings, stored in {@see settingColumn()} on `company_settings`. Null
 * there means the built-in text. See Docs/orders/ORDER-RETURN-MESSAGE.md §٥ and
 * Docs/outsourced-products/OUTSOURCED-PRODUCTS.md §10.
 *
 * **{@see INVOICE_PLACEHOLDER}** is replaced with the order's code in every text. A text without
 * it is allowed: the admin may prefer a message that does not quote the number.
 * **{@see ITEMS_PLACEHOLDER}** belongs to the vendor text only: the server writes the order's
 * lines and colours there, so the admin words the frame and never the list.
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

    /** To the vendor of an outsourced order — what to make. */
    case VendorRequest = 'vendor_request';

    public const INVOICE_PLACEHOLDER = '{رقم_الفاتورة}';

    public const ITEMS_PLACEHOLDER = '{الأصناف}';

    /**
     * The placeholders the admin may use in this text.
     *
     * @return list<string>
     */
    public function placeholders(): array
    {
        return $this === self::VendorRequest
            ? [self::INVOICE_PLACEHOLDER, self::ITEMS_PLACEHOLDER]
            : [self::INVOICE_PLACEHOLDER];
    }

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
            self::VendorRequest => 'رسالة المورد — طلبيات التصنيع',
        };
    }

    /**
     * The built-in wording, used whenever the admin has not typed one.
     *
     * The two ready texts are the owner's own (2026-10-28, 2026-11-10), moved here from the app
     * unchanged; the two return texts and the vendor text were approved on 2026-11-14.
     */
    public function defaultBody(): string
    {
        $invoice = self::INVOICE_PLACEHOLDER;
        $items = self::ITEMS_PLACEHOLDER;

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
            self::VendorRequest => [
                "السلام عليكم ، يومك طيب إن شاء الله\nطلبية جديدة من دعاية رقم : [ {$invoice} ]",
                $items,
                "التصميم المعتمد نرسلوه ليكم في رسالة منفصلة .\nنرجو تأكيد الاستلام وموعد التسليم .",
            ],
        });
    }
}
