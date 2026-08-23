<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Application\Api\V1\Resources\OrderResource;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\TransitionField;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;

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
    /** What the money box is called in the payload, and the key its method hangs off. */
    public const PAYMENT_AMOUNT = 'payment_amount';

    public const PAYMENT_METHOD = 'payment_method';

    /**
     * [$actor] is who is making the move, and it decides one thing only: whether the money box
     * is offered. A driver may hand a parcel over without being trusted with the till, so the
     * field is withheld rather than the move. Null — a console command, an importer — is treated
     * as nobody, and gets no box.
     *
     * @return list<TransitionField>
     */
    public static function for(Order $order, OrderStatus $target, ?User $actor = null): array
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

        // **No parcel weight is asked for here any more.** `orders.weight_kg` was written by
        // this move and read by nothing that computed anything: not the invoice, which is built
        // from the line quantities; not the carrier; not costing. It was demanded of every
        // kilo-priced order on the grounds that «الوزن هو ما تُحاسب عليه», which was never true
        // of the code. What comes off the shelf is asked for below instead — per line, and only
        // where nobody could work it out.
        if ($target === OrderStatus::Ready) {
            // Read by the preview, by the per-line fields and by `isStockedInAnotherUnit()` on
            // each of them. `items.product` is not in the list query's eager set and strict mode
            // turns a forgotten load into an exception rather than a query per line, so it is
            // asked for once here rather than three times below.
            $order->loadMissing('items.product');

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
                    ? self::deductionPreview($order)
                    : 'خُصم المخزون بالفعل من هذه الطلبية',
            );

            // **What actually comes off the shelf, for the lines where nobody could work it
            // out.** A run sold by the piece and stocked by the kilo has two figures and no
            // conversion between them — see {@see OrderItem::isStockedInAnotherUnit()} — so
            // the person who has the parcel in front of them is asked, in the shelf's unit,
            // once per line that needs it. Every other line is silent: what was sold is what
            // leaves, and a box asking a foreman to retype a number the order already holds can
            // only ever introduce a difference between the two.
            //
            // Gated on `stock_deducted_at` exactly as the warehouse above it is: an order whose
            // stock has already gone is offered the field and not made to answer it.
            foreach ($order->items as $item) {
                if (! $item->isStockedInAnotherUnit()) {
                    continue;
                }

                $fields[] = TransitionField::number(
                    key: self::stockQuantityKey($item),
                    label: "المخصوم من {$item->variant_label} ({$item->stockUnit()->label()})",
                    required: $order->stock_deducted_at === null,
                    hint: "المباع {$item->quantity} {$item->pricing_unit->label()} — والمخزن يُنقص بال{$item->stockUnit()->label()}",
                    // An answer, not a placeholder, and only where one already exists: an order
                    // taken while the create form still asked for this carries what was measured
                    // then, and re-asking from an empty box invites a second figure for a parcel
                    // that was weighed once.
                    value: $item->warehouse_quantity !== null ? (string) $item->warehouse_quantity : null,
                );
            }
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

        // What was just handed over, and how.
        //
        // **The money box, at the two moments money actually appears.** The customer collecting
        // at the counter pays there; the courier's takings come back at settlement. Until this
        // existed, the person holding the cash moved the order, left the screen, opened
        // «الدفعات» and typed the figure a second time — and skipping the second step is how
        // orders ended up closed with nothing recorded against them.
        //
        // It replaced «المبلغ المستلم» (`collected_amount`) on «تم التسوية» rather than sitting
        // beside it. That field asked this same question and answered none of it: it wrote a
        // column no total added up, so an order could carry «المدفوع ٥٠٠» and «المستلم فعلياً
        // ٤٥٠» at once and nothing could say which was true. What it was for — «أيّ الطلبيات رجع
        // مالها ناقصاً» — the ledger now answers exactly, and the column stays in the database
        // for the orders written before this.
        array_push($fields, ...self::money($order, $target, $actor));

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
     * The pair of fields that turn a status change into a ledger entry, or nothing at all.
     *
     * **Four conditions, and each of them removes a box that could only fail.**
     *
     * - Only «تم الاستلام» and «تم التسوية». Money changes hands when the parcel does and when
     *   the driver's takings come back; a box on «قيد الطباعة» would be a money field on a
     *   screen with no money in it.
     * - Only for somebody holding `orders.payments.record`. The move itself is a different
     *   grant, and a driver who may drop a parcel off is not thereby trusted with the till —
     *   withholding the field rather than the move is the whole reason [$actor] is passed in.
     * - Only while something is owed. `RecordOrderPayment` refuses anything over the remainder,
     *   so on a settled account every possible answer is a 422.
     * - Never a method obliging a receipt. «حوالة» must carry its الواصل — see
     *   {@see PaymentMethod::requiresReceipt()} — and this screen uploads no files, so the
     *   method is left off the picker instead of offered and then refused. A transfer is
     *   recorded from the payments screen, which does take one.
     *
     * @return list<TransitionField>
     */
    private static function money(Order $order, OrderStatus $target, ?User $actor): array
    {
        if ($target !== OrderStatus::Delivered && $target !== OrderStatus::Settled) {
            return [];
        }

        if (! $actor?->can(PermissionName::RecordOrderPayments->value)) {
            return [];
        }

        $remaining = $order->remainingAmount();

        if (bccomp($remaining, '0', Money::SCALE) <= 0) {
            return [];
        }

        // **Pre-filled at settlement and empty at the counter, because the two moments differ.**
        // Settling *means* the money came back, and nearly always all of it: the box opens
        // holding the remainder and agreeing costs a tap. Handing bags over means no such thing
        // — the customer may pay all of it, some of it, or none — so nothing is suggested.
        $settling = $target === OrderStatus::Settled;

        $methods = array_values(array_filter(
            PaymentMethod::cases(),
            fn (PaymentMethod $method) => ! $method->requiresReceipt(),
        ));

        return [
            TransitionField::number(
                key: self::PAYMENT_AMOUNT,
                label: 'المبلغ المقبوض',
                // Never required, at either end. An order paid in full when it was taken is
                // handed over with the box left alone, and one settled after the money was
                // recorded from the payments screen needs nothing here either.
                required: false,
                // The ceiling is the debt: an overpayment is refused by the ledger anyway, and
                // being told so at the field beats being told so after the move is attempted.
                max: (float) $remaining,
                hint: $settling
                    ? "المتبقي {$remaining} — يُسجَّل دفعةً في سجل الطلبية"
                    : "المتبقي {$remaining} — اتركه فارغاً إن لم يُقبض شيء الآن",
                value: $settling ? $remaining : null,
            ),
            TransitionField::paymentMethod(
                key: self::PAYMENT_METHOD,
                label: 'طريقة الدفع',
                methods: $methods,
                // Meaningless without an amount and mandatory with one — the ledger takes no
                // entry lacking it.
                requiredWith: self::PAYMENT_AMOUNT,
                hint: 'الحوالة تُسجَّل من شاشة الدفعات لأنها تتطلّب واصلاً',
                // Cash, because a counter takes cash. An answer, not a placeholder: agreeing
                // costs no taps and disagreeing costs one.
                value: PaymentMethod::Cash->value,
            ),
        ];
    }

    /** What the per-line box for one line is called in the payload. */
    public static function stockQuantityKey(OrderItem $item): string
    {
        return "warehouse_quantity_{$item->getKey()}";
    }

    /**
     * «يُخصم منه…» said with the actual figures, one line per size.
     *
     * **The person naming the warehouse could not see what was about to leave it.** What is
     * deducted is {@see OrderItem::producedQuantity()} — `warehouse_quantity ?? quantity` — in
     * the *product's* `stock_unit`, and since that unit became settable it need not be the unit
     * the line is sold in. So an order for 300 bags can take 12.5 kilograms off the shelf, and
     * neither number nor unit was anywhere on the screen that asked which shelf.
     *
     * **A line nobody has weighed yet is named, not numbered.** `producedQuantity()` falls back
     * to the sold quantity, which for a line stocked in another unit is a piece count wearing a
     * kilogram label — «٥٠٠ كيلوغرام» for five hundred bags. That fallback is the bug the box
     * below this hint exists to close, and printing it here would be the same lie in the same
     * breath as the question that fixes it.
     *
     * **A hint rather than a field, because it is not an input.** The app renders whatever the
     * server hands it — see {@see OrderResource} — so this
     * reaches every client with no release, and cannot drift from what `DeductOrderStock` will
     * actually do because both read the same accessor.
     *
     * Falls back to the bare sentence for an order with no lines: a heading introducing an empty
     * list reads as a bug.
     */
    private static function deductionPreview(Order $order): string
    {
        $lines = $order->items
            ->map(fn (OrderItem $item): string => sprintf(
                '• %s — %s',
                $item->variant_label,
                $item->isStockedInAnotherUnit() && $item->warehouse_quantity === null
                    ? "بال{$item->stockUnit()->label()}، حسب ما تُدخله أدناه"
                    : "{$item->producedQuantity()} {$item->stockUnit()->label()}",
            ))
            ->all();

        if ($lines === []) {
            return 'يُخصم منه ما تستهلكه هذه الطلبية من المخزون';
        }

        return "يُخصم منه ما تستهلكه هذه الطلبية من المخزون:\n".implode("\n", $lines);
    }
}
