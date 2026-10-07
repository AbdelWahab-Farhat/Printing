<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\RecalculateOrderPayments;
use App\Domain\Order\Actions\ReviewOrderPayment;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Exceptions\PaymentCannotBeSettled;
use App\Domain\Order\Exceptions\PaymentNeedsNoReview;
use App\Domain\Order\Exceptions\ReversedPaymentNeedsNoReview;
use App\Domain\Order\Queries\PaymentReviewQueue;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Support\Exceptions\DomainException;
use App\Support\Media\StoreReceipt;
use Database\Factories\OrderPaymentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

/**
 * One entry in an order's money ledger.
 *
 * **Nothing updates one and nothing deletes one.** There is no route that does, and a correction
 * is a further entry pointing back at this one — see {@see OrderPaymentType}. A ledger you can
 * rewrite explains nothing, and being able to explain is the entire reason this table exists
 * rather than a `paid_amount` column that goes up and down.
 *
 * `amount` is always positive; the direction is the type's, so a sum over the table cannot be
 * quietly wrong because somebody stored a row negative. The database holds that as a CHECK too.
 *
 * Only the fields a human genuinely supplies are fillable. The type is decided by which action
 * ran, `recorded_by` is stamped from the signed-in user, `reverses_payment_id` is set by the
 * reversal itself, and the five `receipt_*` columns are written by
 * {@see StoreReceipt} from the file it actually stored — so no payload can invent an
 * entry type, attribute a collection to a colleague, point a correction at somebody else's row,
 * or claim a receipt exists at a path of its choosing. See RULES.md §9.4.
 */
#[UseFactory(OrderPaymentFactory::class)]
#[Fillable(['amount', 'method', 'reference', 'paid_at', 'notes'])]
class OrderPayment extends Model
{
    /** @use HasFactory<OrderPaymentFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => OrderPaymentType::class,
            'method' => PaymentMethod::class,
            // A string, not a float: this is summed into `orders.paid_amount`, and money that
            // is summed must stay exact.
            'amount' => 'decimal:2',
            // How much of a payment was beyond the debt, or of a refund handed that back. See
            // {@see contributions()}.
            'excess_amount' => 'decimal:2',
            'paid_at' => 'datetime',
            'receipt_size_bytes' => 'integer',
            'requires_review' => 'boolean',
            'reviewed_at' => 'datetime',
        ];
    }

    /**
     * Whether the paper backing this entry is on file.
     */
    public function hasReceipt(): bool
    {
        return $this->receipt_path !== null;
    }

    /**
     * Whether the receipt is a picture the app can draw itself, as opposed to a PDF it hands
     * to the phone.
     *
     * Answered from the *stored* path, whose extension {@see StoreReceipt} derived from
     * the sniffed bytes — so a JPEG that arrived calling itself `waseel.pdf` still answers
     * true. Published on the resource so the app keeps no copy of the format list.
     */
    public function receiptIsImage(): bool
    {
        if (! $this->hasReceipt()) {
            return false;
        }

        $extension = strtolower(pathinfo((string) $this->receipt_path, PATHINFO_EXTENSION));

        return in_array($extension, ['jpg', 'jpeg', 'png', 'webp'], true);
    }

    /**
     * A link to the receipt, built on demand from the disk it actually lives on.
     *
     * **Never stored**, exactly like a customer's design: the row records the disk and the path,
     * so moving to S3 is a config change with no migration. And the disk is private — a receipt
     * carries somebody's bank details — so in production this is a signed link that expires, and
     * the capability is asked of the disk rather than assumed.
     */
    public function receiptUrl(): ?string
    {
        if (! $this->hasReceipt()) {
            return null;
        }

        $disk = Storage::disk($this->receipt_disk);

        return $disk->providesTemporaryUrls()
            ? $disk->temporaryUrl($this->receipt_path, now()->addMinutes(config('media.temporary_url_minutes')))
            : $disk->url($this->receipt_path);
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * The entry this one undoes. Set on a reversal and null on everything else.
     *
     * @return BelongsTo<OrderPayment, $this>
     */
    public function reversedPayment(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reverses_payment_id');
    }

    /**
     * The reversal that undid this entry, if one exists.
     *
     * `hasOne` rather than `hasMany` because a unique index says so: an entry is undone at most
     * once, and the second attempt is refused by the database rather than by a check somebody
     * could forget to write.
     *
     * @return HasOne<OrderPayment, $this>
     */
    public function reversal(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_payment_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    /**
     * Whoever checked this entry and said it is right. Null until somebody has, and after an
     * employee is deleted — the review survives them, only the name goes.
     *
     * @return BelongsTo<User, $this>
     */
    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function isReviewed(): bool
    {
        return $this->reviewed_at !== null;
    }

    /**
     * Whether this entry sits in the reviewer's queue: it needs a check, nobody has made one, and
     * it was not cancelled as a mistake in the meantime. The same three conditions
     * {@see PaymentReviewQueue} filters on.
     */
    public function awaitsReview(): bool
    {
        return $this->requires_review && ! $this->isReviewed() && ! $this->isReversed();
    }

    /**
     * Why this entry may not be marked reviewed — or null when it may.
     *
     * **The one place the rule is written**, so the action that refuses and the resource that
     * greys the button can never disagree: {@see ReviewOrderPayment} throws what this returns, and
     * `OrderPaymentResource` publishes its message as `review_blocked_reason`. The grant itself is
     * the route's, not this method's.
     *
     * **Who recorded the entry does not matter** — the owner decided (2026-10-04) that anybody
     * holding `orders.payments.review` may review, their own entries included. The stamp still
     * says who reviewed, so a self-review is visible beside who recorded.
     */
    public function reviewRefusal(): ?DomainException
    {
        if (! $this->requires_review) {
            return PaymentNeedsNoReview::make();
        }

        if ($this->isReversed()) {
            return ReversedPaymentNeedsNoReview::make();
        }

        return null;
    }

    /**
     * Where the money landed — the cash box, «مصرف علي», Nawris's custody.
     *
     * Null on the entries that moved no money, and on every entry written before the treasury
     * existed: those were counted into the opening balances instead (TREASURY-DESIGN §١١).
     *
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function treasuryAccount(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class, 'treasury_account_id');
    }

    /**
     * «تسوية دفعة» still standing: the operation that carried this payment's money on before the
     * order was settled, and was not taken back since. TREASURY-DESIGN §٢٣.
     *
     * @return HasOne<TreasuryOperation, $this>
     */
    public function standingSettlement(): HasOne
    {
        return $this->hasOne(TreasuryOperation::class, 'order_payment_id')
            ->where('type', OperationType::Settlement->value)
            ->whereNull('reverses_operation_id')
            ->whereDoesntHave('reversedBy');
    }

    public function isSettled(): bool
    {
        if ($this->relationLoaded('standingSettlement')) {
            return $this->standingSettlement !== null;
        }

        return $this->standingSettlement()->exists();
    }

    /**
     * Why this payment's money may not be settled — or null when it may.
     *
     * **The one place the rule is written**, as {@see reviewRefusal()} is for the review: the
     * action throws what this returns, and the resource greys the button with it. Whether the
     * money is still in its account is the treasury's to answer, at the moment it moves it.
     */
    public function settlementRefusal(?Order $order): ?PaymentCannotBeSettled
    {
        return match (true) {
            $this->type !== OrderPaymentType::Payment => PaymentCannotBeSettled::notAPayment(),
            $this->isReversed() => PaymentCannotBeSettled::reversed(),
            $this->treasury_account_id === null => PaymentCannotBeSettled::predatesTreasury(),
            $order === null => PaymentCannotBeSettled::orderMissing(),
            $order->status === OrderStatus::Settled => PaymentCannotBeSettled::orderSettled(),
            $this->isSettled() => PaymentCannotBeSettled::alreadySettled(),
            default => null,
        };
    }

    /**
     * Why this payment's settlement may not be taken back — or null when it may.
     */
    public function unsettlementRefusal(?Order $order): ?PaymentCannotBeSettled
    {
        return match (true) {
            ! $this->isSettled() => PaymentCannotBeSettled::notSettled(),
            $order === null => PaymentCannotBeSettled::orderMissing(),
            // The order's settlement carried whatever was left; money put back into custody now
            // would sit there with nothing left to settle it. Un-settle the order first.
            $order->status === OrderStatus::Settled => PaymentCannotBeSettled::orderSettledCannotUndo(),
            default => null,
        };
    }

    /**
     * Whether this entry has been undone.
     *
     * Reads what was loaded before it asks the database — this is answered for every row of a
     * ledger being rendered, and a query per row is how a screen becomes slow.
     */
    public function isReversed(): bool
    {
        if ($this->relationLoaded('reversal')) {
            return $this->reversal !== null;
        }

        return $this->reversal()->exists();
    }

    /**
     * Whether this entry may be undone at all.
     *
     * **A payment or a write-off, and each only once.** Both are claims that can simply be
     * wrong — a figure mistyped at the counter, a difference forgiven on the wrong order — and
     * neither moved cash that would have to be fetched back to undo it.
     *
     * Reversing a reversal is a maze with no floor: the second one would have to mean "the
     * correction was wrong", which is the same statement as a new payment and reads far worse in
     * a ledger. Somebody who reversed by mistake records the payment again.
     *
     * A refund is money that genuinely left the drawer. Undoing it is a *payment* — the customer
     * gave it back — not a claim that it never happened.
     */
    public function isReversible(): bool
    {
        return $this->type->isReversible() && ! $this->isReversed();
    }

    /**
     * Which of the order's two totals this entry moves: what was forgiven, or what was paid.
     *
     * **A reversal answers for the row it undoes**, and this is the only place that lookup
     * happens. A reversal of a write-off must come back off `written_off_amount` — taking it off
     * `paid_amount` instead would leave an order claiming cash it never had, which is the exact
     * confusion the second column exists to prevent.
     *
     * Reads what was loaded before it asks the database, like {@see isReversed()}: the recalculate
     * pass walks a whole ledger, and a query per row is how a save becomes slow.
     */
    public function affectsWriteOff(): bool
    {
        if ($this->type->isWriteOff()) {
            return true;
        }

        if ($this->type !== OrderPaymentType::Reversal) {
            return false;
        }

        return $this->reversedPayment?->type->isWriteOff() ?? false;
    }

    /**
     * Whether this entry moves what the carrier collected at the door rather than either of the
     * other two totals.
     *
     * The exact shape of {@see affectsWriteOff()}, one total along, and it exists for the same
     * reason: **a reversal answers for the row it undoes.** A reversal of a carrier settlement
     * must come back off `carrier_settled_amount` — taking it off `paid_amount` would leave an
     * order claiming cash it never had, and off `written_off_amount` would leave it claiming a
     * loss nobody decided on.
     *
     * Reads what was loaded before it asks the database, like {@see affectsWriteOff()}.
     */
    public function affectsCarrierSettlement(): bool
    {
        if ($this->type->isCarrierSettled()) {
            return true;
        }

        if ($this->type !== OrderPaymentType::Reversal) {
            return false;
        }

        return $this->reversedPayment?->type->isCarrierSettled() ?? false;
    }

    /**
     * What this entry does to the total it belongs to, signed.
     *
     * The one place the direction of a row is turned into arithmetic, so no caller has to
     * remember which of the four types subtracts. **Which total it lands in is a separate
     * question** — see {@see affectsWriteOff()} — and keeping the two apart is what let a fourth
     * entry type arrive without a single caller re-deriving the sign rule.
     */
    public function signedAmount(): string
    {
        $amount = (string) $this->amount;

        return $this->type->isCredit() ? $amount : '-'.$amount;
    }

    /**
     * What this entry does to each of the order's four totals, signed.
     *
     * **The one place the excess is split off**, so {@see RecalculateOrderPayments} adds rows up
     * without knowing which part of a payment was beyond the debt:
     *
     * | entry | paid | written off | carrier | excess |
     * | --- | --- | --- | --- | --- |
     * | payment of 100, 1 beyond the debt | +99 | | | +1 |
     * | refund of 30, 1 of it the excess | −29 | | | −1 |
     * | write-off | | +amount | | |
     * | carrier settlement | | | +amount | |
     * | excess kept | | | | −amount |
     * | reversal | the row it undoes, negated | | | |
     *
     * A reversal whose original is somehow missing falls back to taking its amount off `paid`,
     * which is what every reversal did before there were other totals.
     *
     * @return array{paid: string, written_off: string, carrier_settled: string, excess: string}
     */
    public function contributions(): array
    {
        $amount = (string) $this->amount;
        $excess = (string) $this->excess_amount;
        $none = ['paid' => '0', 'written_off' => '0', 'carrier_settled' => '0', 'excess' => '0'];

        return match ($this->type) {
            OrderPaymentType::Payment => [...$none, 'paid' => bcsub($amount, $excess, 2), 'excess' => $excess],
            OrderPaymentType::Refund => [...$none, 'paid' => bcsub($excess, $amount, 2), 'excess' => '-'.$excess],
            OrderPaymentType::WriteOff => [...$none, 'written_off' => $amount],
            OrderPaymentType::CarrierSettled => [...$none, 'carrier_settled' => $amount],
            OrderPaymentType::ExcessKept => [...$none, 'excess' => '-'.$amount],
            OrderPaymentType::Reversal => $this->reversedPayment === null
                ? [...$none, 'paid' => '-'.$amount]
                : array_map(
                    fn (string $part): string => bcsub('0', $part, 2),
                    $this->reversedPayment->contributions(),
                ),
        };
    }
}
