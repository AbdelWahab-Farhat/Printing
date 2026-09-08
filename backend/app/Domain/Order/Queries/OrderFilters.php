<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentStatus;

final readonly class OrderFilters
{
    /**
     * @param  list<OrderStatus>|null  $statuses  more than one, because the work queues staff
     *                                            actually want are groups: "everything still in
     *                                            production", "everything that came back".
     */
    public function __construct(
        /** Matches the order number, the customer's name or their phone. */
        public ?string $search = null,
        public ?array $statuses = null,
        public ?int $customerId = null,
        public ?int $cityId = null,
        public ?string $from = null,
        public ?string $to = null,
        /**
         * @var list<PaymentStatus>|null Repeatable like `status`, and for the same reason: «أرِني
         *                               ما لم يُدفع» in practice means unpaid *and* part-paid,
         *                               and making somebody run the list twice to see one queue
         *                               is how a filter goes unused.
         */
        public ?array $paymentStatuses = null,
        /**
         * Null is «كلاهما» — the list as it has always been. `false` is a question in its own
         * right («أرِني ما ليس مستعجلاً») rather than the absence of one, which is why this is
         * a nullable bool and not a flag.
         */
        public ?bool $isUrgent = null,
        /** Which end of the queue the list starts at. Never null: there is always an order. */
        public OrderSort $sort = OrderSort::Newest,
    ) {}

    /**
     * @param  array<string, mixed>  $query
     */
    public static function fromArray(array $query): self
    {
        $search = trim((string) ($query['search'] ?? ''));

        return new self(
            search: $search !== '' ? $search : null,
            statuses: self::statuses($query),
            customerId: self::intOrNull($query['customer_id'] ?? null),
            cityId: self::intOrNull($query['city_id'] ?? null),
            from: self::textOrNull($query['from'] ?? null),
            to: self::textOrNull($query['to'] ?? null),
            paymentStatuses: self::paymentStatuses($query),
            isUrgent: self::boolOrNull($query['urgent'] ?? null),
            sort: OrderSort::fromRequest($query['sort'] ?? null),
        );
    }

    /**
     * The same question with the payment filter dropped.
     *
     * What {@see OrderPaymentStatusCountsQuery} counts against: narrowing the counts to the
     * state already chosen would make every one of them equal the list's own length. Expressed
     * as a copy rather than a flag on `applyFilters()` because it is the *filter* that is being
     * asked a different question here, not the query — the status counts use the flag because
     * they genuinely share this object with the list.
     */
    public function withoutPaymentStatuses(): self
    {
        return new self(
            search: $this->search,
            statuses: $this->statuses,
            customerId: $this->customerId,
            cityId: $this->cityId,
            from: $this->from,
            to: $this->to,
            paymentStatuses: null,
            isUrgent: $this->isUrgent,
            sort: $this->sort,
        );
    }

    /**
     * Same shape as {@see statuses()}, and unknown values are dropped the same way.
     *
     * @param  array<string, mixed>  $query
     * @return list<PaymentStatus>|null
     */
    private static function paymentStatuses(array $query): ?array
    {
        $raw = $query['payment_status'] ?? null;

        if ($raw === null || $raw === '' || $raw === []) {
            return null;
        }

        $statuses = array_filter(array_map(
            fn (mixed $value) => PaymentStatus::tryFrom((string) $value),
            is_array($raw) ? $raw : [$raw],
        ));

        return $statuses === [] ? null : array_values($statuses);
    }

    /**
     * Accepts `status=ready` and `status[]=ready&status[]=printing` alike, and quietly drops a
     * value that names no status — a filter nobody can satisfy would return an empty page and
     * look like "no orders" rather than "you asked for something that does not exist".
     *
     * @param  array<string, mixed>  $query
     * @return list<OrderStatus>|null
     */
    private static function statuses(array $query): ?array
    {
        $raw = $query['status'] ?? null;

        if ($raw === null || $raw === '' || $raw === []) {
            return null;
        }

        $statuses = array_filter(array_map(
            fn (mixed $value) => OrderStatus::tryFrom((string) $value),
            is_array($raw) ? $raw : [$raw],
        ));

        return $statuses === [] ? null : array_values($statuses);
    }

    /**
     * `1`/`0`, `true`/`false` and `"yes"`/`"no"` all arrive as strings in a query string, so the
     * reading is Laravel's own rather than a cast — `(bool) "0"` is false but `(bool) "false"`
     * is true, which would turn «أرِني ما ليس مستعجلاً» into its opposite.
     *
     * Anything that is neither is treated as «لم يُسأل», for the reason a status naming nothing
     * is dropped: a filter nobody can satisfy returns an empty page and reads as «لا طلبيات».
     */
    private static function boolOrNull(mixed $value): ?bool
    {
        if ($value === null || $value === '') {
            return null;
        }

        return filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    }

    private static function intOrNull(mixed $value): ?int
    {
        return $value !== null && $value !== '' ? (int) $value : null;
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
