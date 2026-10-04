<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\DeleteOrder;
use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Enums\PaymentStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «الزائد للزبون» — 100 handed over on an order of 99, because nobody had the one dinar.
 *
 * **What the suite holds the feature to**: the payment is taken whole, as one entry, and only
 * after somebody confirmed it; the order is paid 99 and its sale stays 99; the one dinar is owed
 * back to the customer — on the order and in the treasury's «علينا» — until it is refunded or
 * kept; and every one of those steps can be undone without the numbers parting company.
 *
 * See Docs/payments/PAYMENT-REVIEW-AND-OVERPAY.md. Arrange - Act - Assert throughout.
 */
class OrderOverpaymentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /**
     * @param  list<PermissionName>  $permissions
     * @return array<string, string>
     */
    private function auth(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function cashier(): array
    {
        return $this->auth([
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
            PermissionName::KeepOrderExcess,
            PermissionName::MarkOrdersDelivered,
        ]);
    }

    private function order(string $total = '99.00', OrderStatus $status = OrderStatus::Ready): Order
    {
        return Order::factory()->create([
            'items_total' => $total,
            'delivery_price' => '0.00',
            'grand_total' => $total,
            'status' => $status,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    private function pay(array $headers, Order $order, array $payload): TestResponse
    {
        return $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments", [
            'method' => PaymentMethod::Cash->value,
            ...$payload,
        ]);
    }

    /** @param  array<string, string>  $headers */
    private function overpay(array $headers, Order $order, string $amount = '100.00'): OrderPayment
    {
        $response = $this->pay($headers, $order, ['amount' => $amount, 'accept_overpayment' => true])
            ->assertCreated();

        return OrderPayment::query()->findOrFail($response->json('data.payment.id'));
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    private function refund(array $headers, Order $order, array $payload): TestResponse
    {
        return $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
            'method' => PaymentMethod::Cash->value,
            ...$payload,
        ]);
    }

    /** @param  array<string, string>  $headers */
    private function keep(array $headers, Order $order): TestResponse
    {
        return $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/keep-excess", [
            'notes' => 'الزبون لم يطلب الباقي',
        ]);
    }

    /** @param  array<string, string>  $headers */
    private function reverse(array $headers, OrderPayment $entry): TestResponse
    {
        return $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$entry->order_id}/payments/{$entry->id}/reverse", ['reason' => 'خطأ']);
    }

    private function cashBox(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', AccountKind::Cash->value)->where('is_default', true)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    private function owedToCustomers(): string
    {
        return $this->balance(app(TreasuryService::class)->customerExcessPayable());
    }

    // ── taking it ───────────────────────────────────────────────────────────────────────

    public function test_more_than_is_owed_is_refused_until_somebody_confirms_it(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');

        // Act
        $response = $this->pay($headers, $order, ['amount' => '100.00']);

        // Assert — the confirmation is what still catches 500 typed for 50.
        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['amount'])
            ->assertJsonPath('message', 'المبلغ (100.00) أكبر من المتبقي على الطلبية (99.00) — أكّد تسجيل الزائد للزبون');
        $this->assertSame(0, OrderPayment::query()->count());
    }

    public function test_a_confirmed_overpayment_is_one_entry_and_the_order_is_paid_what_it_cost(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');

        // Act
        $response = $this->pay($headers, $order, ['amount' => '100.00', 'accept_overpayment' => true]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.payment.amount', '100.00')
            ->assertJsonPath('data.payment.excess_amount', '1.00')
            ->assertJsonPath('data.summary.paid_amount', '99.00')
            ->assertJsonPath('data.summary.excess_amount', '1.00')
            ->assertJsonPath('data.summary.remaining_amount', '0.00')
            ->assertJsonPath('data.summary.payment_status', PaymentStatus::Overpaid->value);

        $order->refresh();
        $this->assertSame('99.00', (string) $order->grand_total, 'the sale is untouched');
        $this->assertSame('99.00', (string) $order->paid_amount);
        $this->assertSame('1.00', (string) $order->excess_amount);
        $this->assertSame(1, OrderPayment::query()->where('order_id', $order->id)->count());
    }

    public function test_the_drawer_holds_all_of_it_and_the_treasury_owes_the_customer_the_rest(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $before = $this->balance($this->cashBox());

        // Act
        $this->overpay($headers, $order);

        // Assert — 100 in the drawer, and «علينا» one dinar.
        $this->assertSame(bcadd($before, '100.00', 2), $this->balance($this->cashBox()));
        $this->assertSame('-1.00', $this->owedToCustomers());
    }

    public function test_an_order_already_paid_in_full_takes_a_confirmed_amount_as_all_excess(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->pay($headers, $order, ['amount' => '99.00'])->assertCreated();

        // Act
        $payment = $this->overpay($headers, $order, '5.00');

        // Assert
        $this->assertSame('5.00', (string) $payment->excess_amount);
        $this->assertSame('99.00', (string) $order->fresh()->paid_amount);
        $this->assertSame('5.00', (string) $order->fresh()->excess_amount);
    }

    public function test_a_payload_cannot_name_its_own_excess(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');

        // Act
        $response = $this->pay($headers, $order, ['amount' => '50.00', 'excess_amount' => '40.00']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.payment.excess_amount', '0.00');
        $this->assertSame('0.00', (string) $order->fresh()->excess_amount);
    }

    public function test_the_overpaid_order_is_found_by_the_payment_status_filter(): void
    {
        // Arrange
        $headers = $this->cashier();
        $overpaid = $this->order('99.00');
        $paid = $this->order('99.00');
        $this->overpay($headers, $overpaid);
        $this->pay($headers, $paid, ['amount' => '99.00'])->assertCreated();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson('/api/v1/orders?payment_status[]='.PaymentStatus::Overpaid->value);

        // Assert
        $response->assertOk();
        $ids = array_column($response->json('data'), 'id');
        $this->assertContains($overpaid->id, $ids);
        $this->assertNotContains($paid->id, $ids);
    }

    // ── handing it back, or keeping it ──────────────────────────────────────────────────

    public function test_a_refund_hands_the_excess_back_first(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->overpay($headers, $order);

        // Act
        $response = $this->refund($headers, $order, ['amount' => '1.00']);

        // Assert — the order is still paid 99, and nobody is owed anything.
        $response->assertCreated()
            ->assertJsonPath('data.payment.excess_amount', '1.00')
            ->assertJsonPath('data.summary.paid_amount', '99.00')
            ->assertJsonPath('data.summary.excess_amount', '0.00')
            ->assertJsonPath('data.summary.payment_status', PaymentStatus::Paid->value);
        $this->assertSame('0.00', $this->owedToCustomers());
    }

    public function test_a_larger_refund_takes_the_excess_and_then_the_payment(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->overpay($headers, $order);

        // Act
        $response = $this->refund($headers, $order, ['amount' => '10.00']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.payment.excess_amount', '1.00')
            ->assertJsonPath('data.summary.paid_amount', '90.00')
            ->assertJsonPath('data.summary.excess_amount', '0.00');
    }

    public function test_a_refund_may_reach_what_was_paid_and_the_excess_together_and_no_further(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->overpay($headers, $order);

        // Act
        $tooMuch = $this->refund($headers, $order, ['amount' => '100.01']);
        $all = $this->refund($headers, $order, ['amount' => '100.00']);

        // Assert
        $tooMuch->assertUnprocessable();
        $all->assertCreated()
            ->assertJsonPath('data.summary.paid_amount', '0.00')
            ->assertJsonPath('data.summary.excess_amount', '0.00');
    }

    public function test_keeping_the_excess_takes_it_off_what_is_owed_and_leaves_the_sale_alone(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->overpay($headers, $order);
        $drawer = $this->balance($this->cashBox());

        // Act
        $response = $this->keep($headers, $order);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('message', 'اعتُبر الزائد إيراداً')
            ->assertJsonPath('data.payment.type', OrderPaymentType::ExcessKept->value)
            ->assertJsonPath('data.payment.amount', '1.00')
            ->assertJsonPath('data.payment.method', null)
            ->assertJsonPath('data.payment.requires_review', false)
            ->assertJsonPath('data.payment.is_reversible', true)
            ->assertJsonPath('data.summary.paid_amount', '99.00')
            ->assertJsonPath('data.summary.excess_amount', '0.00')
            ->assertJsonPath('data.summary.payment_status', PaymentStatus::Paid->value);

        // No cash moved — the dinar has been in the drawer since the payment — and «علينا» is
        // back at nothing.
        $this->assertSame($drawer, $this->balance($this->cashBox()));
        $this->assertSame('0.00', $this->owedToCustomers());
    }

    public function test_there_is_nothing_to_keep_on_an_order_that_holds_no_excess(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->pay($headers, $order, ['amount' => '99.00'])->assertCreated();

        // Act
        $response = $this->keep($headers, $order);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('message', 'لا زائد على هذه الطلبية ليُعتبر إيراداً');
    }

    public function test_keeping_it_costs_its_own_grant(): void
    {
        // Arrange
        $order = $this->order('99.00');
        $this->overpay($this->cashier(), $order);
        $headers = $this->auth([PermissionName::RecordOrderPayments, PermissionName::ReverseOrderPayments]);

        // Act
        $response = $this->keep($headers, $order);

        // Assert
        $response->assertForbidden();
        $this->assertSame('1.00', (string) $order->fresh()->excess_amount);
    }

    // ── undoing ─────────────────────────────────────────────────────────────────────────

    public function test_reversing_the_keep_owes_the_customer_again(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->overpay($headers, $order);
        $kept = OrderPayment::query()->findOrFail($this->keep($headers, $order)->json('data.payment.id'));

        // Act
        $response = $this->reverse($headers, $kept);

        // Assert
        $response->assertCreated()->assertJsonPath('data.summary.excess_amount', '1.00');
        $this->assertSame('-1.00', $this->owedToCustomers());
    }

    public function test_reversing_an_overpayment_takes_back_the_cash_and_the_debt_together(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $before = $this->balance($this->cashBox());
        $payment = $this->overpay($headers, $order);

        // Act
        $response = $this->reverse($headers, $payment);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.summary.paid_amount', '0.00')
            ->assertJsonPath('data.summary.excess_amount', '0.00');
        $this->assertSame($before, $this->balance($this->cashBox()));
        $this->assertSame('0.00', $this->owedToCustomers());
    }

    public function test_a_payment_whose_excess_was_kept_is_not_reversed_before_the_keep(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $payment = $this->overpay($headers, $order);
        $this->keep($headers, $order)->assertCreated();

        // Act
        $response = $this->reverse($headers, $payment);

        // Assert
        $response->assertUnprocessable()->assertJsonPath(
            'message',
            'زائد هذه الدفعة رُدّ للزبون أو اعتُبر إيراداً — ألغِ «اعتبار الزائد إيراداً» أولاً، أو سجّل التصحيح بدفعة',
        );
        $this->assertFalse($payment->fresh()->isReversed());
    }

    public function test_deleting_the_order_undoes_the_keep_and_then_the_payment(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = Order::factory()->status(OrderStatus::Delivered)->create([
            'design_fee' => '0.00',
            'delivery_price' => '0.00',
            'discount' => '0.00',
        ]);
        OrderItem::factory()->for($order)->create([
            'quantity' => '99.000',
            'unit_price' => '1.000',
            'line_total' => '99.00',
        ]);
        app(RecalculateOrderTotals::class)($order->refresh());
        $this->overpay($headers, $order);
        $this->keep($headers, $order)->assertCreated();

        // Act
        $deleted = app(DeleteOrder::class)($order->refresh(), User::factory()->create());

        // Assert — nothing paid, nothing owed, and «علينا» back where it started.
        $this->assertSame('0.00', (string) $deleted->paid_amount);
        $this->assertSame('0.00', (string) $deleted->excess_amount);
        $this->assertSame('0.00', $this->owedToCustomers());
    }

    // ── at the counter, on the status screen ────────────────────────────────────────────

    public function test_the_status_screen_asks_before_taking_more_than_is_owed(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00', OrderStatus::OfficePickup);

        // Act
        $transitions = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}")
            ->json('data.available_transitions');
        $delivered = collect($transitions)->firstWhere('status', OrderStatus::Delivered->value);
        $confirm = collect($delivered['fields'])->firstWhere('key', 'payment_accept_overpayment');

        // Assert
        $this->assertNotNull($confirm);
        $this->assertSame('confirmation', $confirm['type']);
        $this->assertSame('المبلغ يزيد على المتبقي — تسجيل الزائد للزبون؟', $confirm['label']);
        $this->assertSame(['key' => 'payment_amount', 'above' => '99.00'], $confirm['confirm_when']);
    }

    public function test_handing_the_bags_over_takes_a_confirmed_overpayment(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00', OrderStatus::OfficePickup);

        // Act
        $response = $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => [
                'payment_amount' => '100',
                'payment_method' => PaymentMethod::Cash->value,
                'payment_accept_overpayment' => '1',
            ],
        ]);

        // Assert
        $response->assertOk();
        $order->refresh();
        $this->assertSame(OrderStatus::Delivered, $order->status);
        $this->assertSame('99.00', (string) $order->paid_amount);
        $this->assertSame('1.00', (string) $order->excess_amount);
    }

    // ── the payable is the orders' alone ────────────────────────────────────────────────

    public function test_nobody_moves_what_customers_are_owed_by_hand(): void
    {
        // Arrange
        $this->overpay($this->cashier(), $this->order('99.00'));
        $headers = $this->auth([PermissionName::ViewTreasury, PermissionName::RecordTreasuryOperations]);
        $payable = app(TreasuryService::class)->customerExcessPayable();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer',
            'from_account_id' => $this->cashBox()->id,
            'to_account_id' => $payable->id,
            'amount' => '1.00',
        ]);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('-1.00', $this->owedToCustomers());
    }
}
