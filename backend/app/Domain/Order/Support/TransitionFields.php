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
 * **It answers for the order, not for the status.** A run priced by the kilo cannot be shelved
 * without a weight while one sold by the piece can, «نواقص» asks a question per line in that
 * line's own unit, and an office pickup is never asked who is carrying the parcel. A table of
 * fields per status could express none of it.
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

        // **A move carries artwork when the order stands in a status that accepts it, on one
        // side of the move or the other.** Two statuses do — «جديدة» and «قيد التصميم», see
        // {@see Order::designsAreEditable()} — and {@see ChangeOrderStatus} attaches while the
        // order is standing in whichever end allows it.
        //
        // Which gives three real moves. Into design, where the queue fills, usually with
        // nothing. Out of design to the press, where it empties with the finished file. And
        // «جديدة» straight to «قيد الطباعة» — the short path, and the commonest one: the customer
        // brought an agreed file, so the order carries it and the press starts, with no detour
        // through a status naming work nobody did. That last case was refused until «جديدة»
        // started accepting versions, and refusing it was the reason staff walked orders into
        // the designer's queue and straight back out.
        //
        // Anywhere else the field could not be honoured, and a field certain to be refused is
        // worse than no field.
        //
        // Every order, whatever its `design_source`. That column answers *whose work the artwork
        // was* — the only one of the two questions that may move money — and not whether there
        // is a file. A reprint that goes back into design because the customer wants the logo
        // moved has artwork to look at like any other.
        $artworkTravels = $target === OrderStatus::Designing
            || ($target === OrderStatus::Printing && $order->designsAreEditable());

        if ($artworkTravels) {
            $fields[] = TransitionField::customerDesigns(
                key: 'design_ids',
                label: 'التصاميم',
                // **Never required, and that is the point of the status.** «قيد التصميم» is the
                // designer's queue: an order is put there *because* the artwork does not exist
                // yet, and it waits there until it does. Demanding a file on the way in made the
                // status unreachable in exactly the case it was built for — and demanding one on
                // the way out would strand every order whose artwork was settled off-screen.
                required: false,
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

        if ($target === OrderStatus::Ready) {
            // Where the stock this order consumes comes out of, asked exactly once per order —
            // see {@see \App\Domain\Order\Actions\DeductOrderStock}. `ready` is reached at most
            // once per order (see `OrderStatus::allowedNext()`), so unlike `printing` this never
            // needs a re-entry guard of its own — `stock_deducted_at` still gates `required`
            // rather than `$fields` itself, so a caller that lands here after a stray retry sees
            // the field, just not required.
            $fields[] = TransitionField::warehouse(
                key: 'warehouse_id',
                label: 'المخزن',
                required: $order->stock_deducted_at === null,
                hint: $order->stock_deducted_at === null
                    ? 'يُخصم منه ما تستهلكه هذه الطلبية من المخزون'
                    : 'خُصم المخزون بالفعل من هذه الطلبية',
            );

            // What came off the press, weighed once for the whole parcel.
            //
            // **Required only when the scale is the invoice.** A run priced by the kilo cannot be
            // shelved without a weight — there would be no answer to what was sold — while for
            // bags sold by the piece the number is for the courier, and a run can be finished
            // before anybody has put it on a scale.
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
                    hint: "من أصل {$item->quantity} — يُخصم من الفاتورة",
                );
            }
        }

        // **Leaving «نواقص» is the same question from the other end.** The stock arrived, and
        // what arrived of it is the number the person holding the delivery note has — so that is
        // what is asked, rather than making them subtract to reach what is left.
        //
        // **Pre-filled with the whole shortage**, because leaving this status nearly always
        // means all of it came: the common answer is a tap, and typing is for the exception. And
        // only the lines that are actually short are asked about — a form listing every size of
        // a five-line order to ask about the one that was missing is a form to be scrolled past.
        //
        // Not offered on the way to «إلغاء تام»: an order written off while short keeps the
        // record of what it was short of.
        if ($order->status === OrderStatus::Shortage && ! $target->isFinal()) {
            foreach ($order->items as $item) {
                if ($item->shortage_quantity === null || bccomp((string) $item->shortage_quantity, '0', 3) <= 0) {
                    continue;
                }

                $fields[] = TransitionField::number(
                    key: "received_{$item->getKey()}",
                    label: "الواصل من نواقص {$item->variant_label} ({$item->pricing_unit->label()})",
                    max: (float) $item->shortage_quantity,
                    hint: "الناقص {$item->shortage_quantity} — ما يبقى منه يُخصم من الفاتورة",
                    value: (string) $item->shortage_quantity,
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
}
