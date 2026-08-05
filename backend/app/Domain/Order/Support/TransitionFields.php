<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Order\DTOs\TransitionField;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;

/**
 * What a particular order owes for a particular move.
 *
 * **One list, read twice.** The resource turns it into the form the app draws, and the request
 * turns it into the rules it accepts — so what is asked for and what is allowed cannot drift
 * apart, and adding a field to a move is a single change here.
 *
 * **It answers for the order, not for the status.** A reprint with `design_source = none` is
 * asked for no artwork at all, and an order that already carries a version is offered another
 * rather than made to supply one. A table of fields per status could express neither.
 */
final class TransitionFields
{
    /**
     * @return list<TransitionField>
     */
    public static function for(Order $order, OrderStatus $target): array
    {
        // **Resolved exactly as the move itself resolves it.** A clerk says "it is going out"
        // and the destination decides whether that means «جاري التوصيل» or «استلام مكتب» — see
        // {@see ChangeOrderStatus::resolve()}. Describing the *requested* status instead would
        // ask an office-pickup order for a shipping company and then refuse the answer, because
        // the move it actually performs never asked.
        if ($target->isDispatch()) {
            $target = OrderStatus::dispatchFor($order->fulfilment_type);
        }

        $fields = [];

        // Every order, whatever its `design_source`. That column answers *whose work the
        // artwork was* — the only one of the two questions that may move money — and not
        // whether there is a file. A reprint that goes back into design because the customer
        // wants the logo moved has artwork to look at like any other.
        if ($target === OrderStatus::Designing) {
            $fields[] = TransitionField::customerDesigns(
                key: 'design_ids',
                label: 'التصاميم',
                // Demanded on the way *in*, offered afterwards: «قيد التصميم» with nothing to
                // look at is the state this rule exists to prevent, but the correction path —
                // printing back to designing — arrives with versions already on the order.
                required: ! self::hasDesigns($order),
                hint: 'تُرفع إلى مكتبة العميل ثم تُربط بالطلبية',
            );
        }

        // Who is carrying it, and the man holding it.
        //
        // **Only on «جاري التوصيل».** The dispatch pair resolves from the order's own address
        // before it reaches here, so an office pickup never sees these: nobody carries a parcel
        // the customer is coming to collect.
        if ($target === OrderStatus::OutForDelivery) {
            $fields[] = TransitionField::shippingCompany(
                key: 'shipping_company_id',
                label: 'شركة التوصيل',
                // Required, because a parcel that has left with nobody named is a parcel nobody
                // can chase. This is the question the return chain is answered from later.
                required: true,
                hint: 'تُسجَّل على الطلبية، ويبقى اسمها فيها ولو حُذفت الشركة لاحقاً',
            );

            $fields[] = TransitionField::text(
                key: 'courier_phone',
                label: 'هاتف المندوب',
                // The company is answerable; the driver is merely reachable, and often nobody
                // has his number at the moment the parcel goes out.
                hint: 'رقم المندوب الذي أخذ الطلبية، إن توفّر',
            );
        }

        // What came off the press, weighed once for the whole parcel.
        //
        // **Required only when the scale is the invoice.** A run priced by the kilo cannot be
        // shelved without a weight — there would be no answer to what was sold — while for bags
        // sold by the piece the number is for the courier, and a run can be finished before
        // anybody has put it on a scale.
        if ($target === OrderStatus::Ready) {
            $byWeight = $order->isPricedByWeight();

            $fields[] = TransitionField::number(
                key: 'weight_kg',
                label: 'الوزن (كجم)',
                required: $byWeight,
                hint: $byWeight
                    ? 'الطلبية مسعّرة بالكيلوغرام — الوزن هو ما تُحاسب عليه'
                    : 'اختياري',
            );
        }

        // «كم الناقص» is meaningless asked of an order: it is a question about a *size*. One
        // field per line, each in that line's own unit and bounded by what was ordered of it —
        // so the app draws the whole thing without knowing what an order line is.
        if ($target === OrderStatus::Shortage) {
            foreach ($order->items as $item) {
                $fields[] = TransitionField::number(
                    key: "shortage_{$item->getKey()}",
                    label: "الناقص من {$item->variant_label} ({$item->pricing_unit->label()})",
                    // Every line optional, and at least one of them insisted on by the domain:
                    // most shortages are one size out of several, and marking the whole form
                    // required would have staff typing zeros to get past it.
                    max: (float) $item->quantity,
                    hint: "من أصل {$item->quantity}",
                );
            }
        }

        // What the courier actually handed over.
        //
        // **Left empty when it matches, which is the point.** Every settlement that goes to plan
        // returns exactly `grand_total`, so a number in this field always means the two differ —
        // and «الطلبيات التي رجع مالها ناقصاً» becomes a query rather than a reading exercise.
        // Pre-filling it with the total would have made agreement and discrepancy look alike.
        if ($target === OrderStatus::Settled) {
            $fields[] = TransitionField::number(
                key: 'collected_amount',
                label: 'المبلغ المستلم',
                hint: "إجمالي الطلبية {$order->grand_total} — املأه فقط إن اختلف ما استُلم",
            );
        }

        // **A note travels with every move, and only a cancellation is made to justify itself.**
        // One field either way: the same input, renamed and made required where an explanation
        // is owed. The app has one way to draw it, and the timeline has one place to read it —
        // `order_status_transitions.reason`, which was nullable and waiting for exactly this.
        //
        // `requires_reason` stays on the transition beside it for clients written before fields
        // existed.
        $mustExplain = $target->requiresReason();

        $fields[] = TransitionField::text(
            key: 'reason',
            label: $mustExplain ? 'السبب' : 'ملاحظة',
            required: $mustExplain,
            multiline: true,
            hint: 'تُسجَّل في سجل الطلبية',
        );

        return $fields;
    }

    /**
     * Whether any version of the artwork is already on the order.
     *
     * Reads what has been loaded before it asks the database: this runs once per offered move,
     * for every order in a list, and a query per row is how a list page becomes slow.
     */
    private static function hasDesigns(Order $order): bool
    {
        if ($order->relationLoaded('designs')) {
            return $order->designs->isNotEmpty();
        }

        // Asked of the attribute bag rather than of the model: strict mode throws for a column
        // that was never selected, so `?? null` is not available here.
        if (array_key_exists('designs_count', $order->getAttributes())) {
            return (int) $order->getAttributes()['designs_count'] > 0;
        }

        return $order->designs()->exists();
    }
}
