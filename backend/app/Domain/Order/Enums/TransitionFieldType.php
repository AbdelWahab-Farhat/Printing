<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

/**
 * The kinds of input a status change can ask for.
 *
 * **A closed set on purpose.** The app draws a widget per type, so a type the app has never
 * heard of is a field nobody can fill — which is why adding a *field* is a backend change alone
 * while adding a *type* is a release on both sides. Two exist because two are needed; the third
 * arrives the day something needs it, not before.
 */
enum TransitionFieldType: string
{
    /** A sentence. `multiline` decides whether it is one line or several. */
    case Text = 'text';

    /**
     * A quantity — kilograms on a scale, pieces off a press.
     *
     * Carries `min` and `max` so the bounds travel with the field: «الناقص من 30*30» can never
     * exceed what was ordered of it, and that is a fact about *this* order rather than a rule
     * the app could know.
     */
    case Number = 'number';

    /**
     * Versions of the artwork, chosen from the customer's own library.
     *
     * The app may upload into that library first — the file is the customer's property and
     * belongs on their record — but what travels here is only ever `customer_designs.id`.
     */
    case CustomerDesigns = 'customer_designs';

    /**
     * One of the carriers, chosen from the list the business maintains.
     *
     * **The options are deliberately not sent with the field.** The app already has the carrier
     * list — it manages it — so inlining the choices here would make every order in a page of
     * fifteen carry the same twenty rows, and would cost a query per row to build. What travels
     * is `shipping_companies.id`, exactly as {@see CustomerDesigns} travels design ids.
     */
    case ShippingCompany = 'shipping_company';

    /**
     * How money that changed hands during the move was handed over.
     *
     * **The one type whose choices do travel with it.** The carrier and the warehouse lists are
     * the app's own — it manages them — but which payment methods may be used *here* is a fact
     * about this screen rather than about the business: «حوالة» obliges a receipt (الواصل) and a
     * status change has nowhere to upload one, so it is left out of the list. An app holding its
     * own copy of `PaymentMethod` would offer all four and be refused on the fourth.
     */
    case PaymentMethod = 'payment_method';

    /**
     * One of the warehouses, chosen from the list the business maintains.
     *
     * Same shape as {@see ShippingCompany}: options are not inlined, and what travels is
     * `warehouses.id`. Asked only once per order — see `TransitionFields::for()` on `ready` —
     * because stock leaves a warehouse exactly once for a given order.
     */
    case Warehouse = 'warehouse';
}
