<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Carrier\CarrierService;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\OrderIsCancelledForPayment;
use App\Domain\Order\Exceptions\PaymentAmountMustBePositive;
use App\Domain\Order\Exceptions\PaymentExceedsRemaining;
use App\Domain\Order\Exceptions\ReceiptRequiredForMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\Money;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use App\Support\Media\StoreReceipt;
use Illuminate\Support\Facades\DB;

/**
 * Money in.
 *
 * **The order row is locked for the whole check-and-write**, and that lock is the reason this
 * action is more than three lines. Reading what is outstanding and then writing an entry against
 * it is the textbook lost update: two clerks taking 300 each against an order that owes 300
 * would both read «متبقٍ ٣٠٠», both find their payment fits, and both commit — leaving an order
 * paid 600 that no single request did anything wrong to produce. `lockForUpdate` makes the
 * second wait, see the first's total, and correctly refuse. Same reasoning as
 * {@see ApplyStockChange} on a shelf balance.
 *
 * The entry and the recalculated total are written in one transaction: either the ledger gains a
 * row and `paid_amount` moves to match, or neither happens. A total that outlived its entry
 * would be the exact failure this design exists to make impossible.
 */
final class RecordOrderPayment
{
    public function __construct(
        private readonly RecalculateOrderPayments $recalculate,
        private readonly StoreReceipt $storeReceipt,
        private readonly TreasuryService $treasury,
    ) {}

    /**
     * @param  string  $accountField  where a refused account is filed — `fields.payment_account_id`
     *                                on the status screen, whose fields hang off `fields`
     * @param  string  $amountField  the same, for an amount beyond the debt nobody confirmed
     */
    public function __invoke(
        Order $order,
        OrderPaymentData $data,
        ?User $actor = null,
        string $accountField = 'treasury_account_id',
        string $amountField = 'amount',
    ): OrderPayment {
        if (bccomp($data->amount, '0', Money::SCALE) <= 0) {
            throw PaymentAmountMustBePositive::make($data->amount);
        }

        // Checked before the lock is taken: it needs nothing from the database, and holding a
        // row while deciding that a form was incomplete buys nothing.
        if ($data->method->requiresReceipt() && $data->receipt === null) {
            throw ReceiptRequiredForMethod::make($data->method);
        }

        return DB::transaction(function () use ($order, $data, $actor, $accountField, $amountField): OrderPayment {
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            // The one closed door, and only for money coming *in*: there is nothing left to pay
            // for. Refunds stay open on a cancelled order — see the exception's own note.
            if ($locked->status === OrderStatus::Cancelled) {
                throw OrderIsCancelledForPayment::make((string) $locked->code);
            }

            $remaining = $this->remaining($locked);

            // **Beyond the debt only when somebody said so.** 100 handed over on an order of 99
            // because nobody had the one dinar is ordinary, and the confirmation is what still
            // tells it apart from 500 typed for 50. With it, the whole 100 is one entry and the 1
            // is owed back to the customer — never part of what the order was paid.
            $excess = '0.00';

            if (bccomp($data->amount, $remaining, Money::SCALE) > 0) {
                if (! $data->acceptOverpayment) {
                    throw PaymentExceedsRemaining::make($data->amount, $remaining, $amountField);
                }

                $excess = Money::round(bcsub($data->amount, $remaining, Money::SCALE));
            }

            $payment = $this->write($locked, $data, $actor, $accountField, $excess);

            ($this->recalculate)($locked);

            return $payment;
        });
    }

    /**
     * What is still owed, floored at zero.
     *
     * Floored rather than left negative so that an order already overpaid — which happens when a
     * discount lands after payment, not because anyone erred — refuses further payments with
     * «المتبقي ٠.٠٠» instead of an amount below zero that reads like a system fault.
     *
     * **Asked of the order rather than subtracted here**, so that what may be collected and what
     * is displayed as owed are the same number. They parted company the day a debt could also be
     * closed by writing it off: an order of 110 with 5 forgiven owes 105, and a private
     * `grand_total - paid_amount` here would have gone on accepting 110.
     */
    private function remaining(Order $order): string
    {
        $remaining = $order->remainingAmount();

        return bccomp($remaining, '0', Money::SCALE) < 0 ? '0.00' : $remaining;
    }

    /**
     * Assigned rather than mass-assigned for the three that decide what this entry *is*: a
     * payload that could set the type could turn a collection into a refund, and one that could
     * set `recorded_by` could put a colleague's name on it. See RULES.md §9.4.
     */
    private function write(
        Order $order,
        OrderPaymentData $data,
        ?User $actor,
        string $accountField,
        string $excess,
    ): OrderPayment {
        $payment = new OrderPayment([
            'amount' => $data->amount,
            'method' => $data->method,
            'reference' => $data->reference,
            'paid_at' => $data->paidAt,
            'notes' => $data->notes,
        ]);

        $payment->order_id = $order->getKey();
        $payment->type = OrderPaymentType::Payment;
        $payment->recorded_by = $actor?->getKey();

        // Into the reviewer's queue — a Nawris webhook's entry included: nobody signed it, so a
        // person checks it against the settlement. Stamped here rather than defaulted in the
        // table, so the rows from before reviews existed stay exempt.
        $payment->requires_review = true;

        // Stamped, never fillable: how much of this entry is beyond the debt is the lock's
        // arithmetic, not a figure a payload may name.
        $payment->excess_amount = $excess;

        // **Where the money landed.** The person's choice if they made one, otherwise — for cash
        // on an order waiting at a branch — that branch's box, otherwise their own account,
        // otherwise the method's default (TREASURY-DESIGN §٥, §١٩). Stamped, never fillable:
        // the account is decided here, by the rules, not by whatever a payload claims. The
        // order is the locked copy, read before this move writes its new status.
        //
        // **وحسابٌ يسمّيه النظام يُؤخذ كما هو** — النورس حين يكتب الـ webhook ما حصّله. **ونقدٌ يُكتب
        // باليد والطردُ ما زال في الطريق يهبط في حساب النورس** إن لم يُختر غيره: الموظف علّم
        // «تم الاستلام» قبل أن يصل تأكيد التسليم، والمالُ ما زال في يد المندوب، والتسوية تنقله.
        $account = $data->systemAccount !== null
            ? $this->treasury->systemAccount($data->systemAccount)
            : $this->treasury->accountFor(
                $data->method->value,
                $actor?->getKey() === null ? null : (int) $actor->getKey(),
                $data->treasuryAccountId,
                field: $accountField,
                pickupCityId: $order->pickupOfficeId(),
                carrierHolds: $data->treasuryAccountId === null
                    // كسولاً لا في البنّاء: `CarrierService` يبلغ هذا الصنف من طرقٍ أخرى.
                    && app(CarrierService::class)->hasParcelOnTheRoad((int) $order->getKey()),
            );

        $payment->treasury_account_id = $account->getKey();

        if ($data->receipt !== null) {
            // forceFill, because the five receipt columns are not fillable: a payload that could
            // set `receipt_path` could claim a receipt exists at a path of its choosing. What is
            // written here is what the disk actually accepted.
            $payment->forceFill(($this->storeReceipt)("payment-receipts/{$order->getKey()}", $data->receipt));
        }

        $payment->save();

        // In the same transaction as the row: the payment and the money it put in an account
        // stand or fall together.
        $this->treasury->post(new MovementData(
            accountId: (int) $account->getKey(),
            direction: MovementDirection::In,
            kind: MovementKind::Payment,
            amount: (string) $payment->amount,
            occurredAt: $payment->paid_at,
            sourceType: $payment->getMorphClass(),
            sourceId: (int) $payment->getKey(),
            orderId: (int) $order->getKey(),
            notes: "دفعة على الطلبية {$order->code}",
            recordedBy: $actor?->getKey() === null ? null : (int) $actor->getKey(),
        ));

        // **And the debt that came with it.** The whole amount is in the drawer — that is the
        // cash — but the part beyond the order is the customer's, so «علينا» says so until it is
        // refunded or kept. Without this the shop would look richer by every dinar of change it
        // could not give. Same source as the cash, so reversing the payment undoes both.
        if (bccomp($excess, '0', Money::SCALE) > 0) {
            $this->treasury->post(new MovementData(
                accountId: (int) $this->treasury->customerExcessPayable()->getKey(),
                direction: MovementDirection::Out,
                kind: MovementKind::CustomerExcess,
                amount: $excess,
                occurredAt: $payment->paid_at,
                sourceType: $payment->getMorphClass(),
                sourceId: (int) $payment->getKey(),
                orderId: (int) $order->getKey(),
                notes: "زائد لزبون الطلبية {$order->code}",
                recordedBy: $actor?->getKey() === null ? null : (int) $actor->getKey(),
            ));
        }

        return $payment;
    }
}
