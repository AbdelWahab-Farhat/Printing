<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\RecordOrderPayment;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

/**
 * «مراجعة الدفعات» — somebody holding the grant checks each payment and refund and says it is right.
 *
 * **Two rules carry the feature**: anybody with the grant may review — their own entries included,
 * by the owner's choice — and nothing waits for a review. The rest is bookkeeping around them — which rows are asked for a check at all
 * (cash in and cash out, recorded from now on), and the queue the reviewer works from.
 *
 * See Docs/payments/PAYMENT-REVIEW-AND-OVERPAY.md. Arrange - Act - Assert throughout.
 */
class OrderPaymentReviewTest extends TestCase
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
     * @return array{0: User, 1: array<string, string>}
     */
    private function userWith(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    /**
     * The counter, which takes the money — and, in a small shop, may also hold the review grant.
     * That is exactly the person the second-person rule exists for.
     *
     * @return array{0: User, 1: array<string, string>}
     */
    private function cashier(): array
    {
        return $this->userWith([
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
            PermissionName::ReviewOrderPayments,
        ]);
    }

    /**
     * The books: checks the entries other people recorded.
     *
     * @return array{0: User, 1: array<string, string>}
     */
    private function reviewer(): array
    {
        return $this->userWith([
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::ReviewOrderPayments,
        ]);
    }

    private function order(string $total = '450.00'): Order
    {
        return Order::factory()->create([
            'items_total' => $total,
            'delivery_price' => '0.00',
            'grand_total' => $total,
            'status' => OrderStatus::Ready,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    private function pay(array $headers, Order $order, array $payload = []): OrderPayment
    {
        $response = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments", [
            'amount' => '100.00',
            'method' => PaymentMethod::Cash->value,
            ...$payload,
        ])->assertCreated();

        return OrderPayment::query()->findOrFail($response->json('data.payment.id'));
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function review(array $headers, OrderPayment $payment, bool $reviewed = true): TestResponse
    {
        return $this->withHeaders($headers)->patchJson(
            "/api/v1/orders/{$payment->order_id}/payments/{$payment->id}/review",
            ['reviewed' => $reviewed],
        );
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $query
     */
    private function queue(array $headers, array $query = []): TestResponse
    {
        return $this->withHeaders($headers)
            ->getJson('/api/v1/order-payments/review-queue?'.http_build_query($query));
    }

    // ── which entries are asked for a check ─────────────────────────────────────────────

    public function test_a_payment_recorded_now_waits_for_a_review(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        $order = $this->order();

        // Act
        $payment = $this->pay($cashier, $order);

        // Assert
        $this->assertTrue($payment->requires_review);
        $this->assertNull($payment->reviewed_at);
        $this->assertTrue($payment->awaitsReview());
    }

    public function test_a_refund_waits_for_a_review_too(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        $order = $this->order();
        $this->pay($cashier, $order, ['amount' => '200.00']);

        // Act
        $response = $this->withHeaders($cashier)->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
            'amount' => '50.00',
            'method' => PaymentMethod::Cash->value,
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.payment.requires_review', true);
    }

    public function test_a_reversal_and_a_write_off_are_not_asked_for_one(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $books] = $this->userWith([PermissionName::WriteOffOrderPayments]);
        $order = $this->order('450.00');
        $payment = $this->pay($cashier, $order, ['amount' => '400.00']);

        // Act
        $reversal = $this->withHeaders($cashier)
            ->postJson("/api/v1/orders/{$order->id}/payments/{$payment->id}/reverse", ['reason' => 'مبلغ خاطئ']);
        $this->pay($cashier, $order, ['amount' => '440.00']);
        $writeOff = $this->withHeaders($books)
            ->postJson("/api/v1/orders/{$order->id}/payments/write-offs", ['amount' => '10.00', 'reason' => 'فكّة']);

        // Assert
        $reversal->assertCreated()->assertJsonPath('data.payment.requires_review', false);
        $writeOff->assertCreated()->assertJsonPath('data.payment.requires_review', false);
    }

    public function test_a_payment_from_before_reviews_existed_is_exempt(): void
    {
        // Arrange — a factory row is what the migration left behind: `requires_review` false.
        [, $reviewer] = $this->reviewer();
        $old = OrderPayment::factory()->forOrder($this->order())->create();

        // Act
        $response = $this->review($reviewer, $old);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('message', 'هذا القيد لا يحتاج مراجعة');
        $this->queue($reviewer)->assertOk()->assertJsonPath('meta.total', 0);
        $this->assertNull($old->fresh()->reviewed_at);
    }

    public function test_a_payload_cannot_review_its_own_payment(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [$colleague] = $this->reviewer();

        // Act
        $payment = $this->pay($cashier, $this->order(), [
            'reviewed_at' => now()->toIso8601String(),
            'reviewed_by' => $colleague->id,
            'requires_review' => false,
        ]);

        // Assert
        $this->assertTrue($payment->requires_review);
        $this->assertNull($payment->reviewed_at);
        $this->assertNull($payment->reviewed_by);
    }

    // ── reviewing ───────────────────────────────────────────────────────────────────────

    public function test_somebody_else_reviews_the_entry_and_it_records_who_and_when(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [$checker, $reviewer] = $this->reviewer();
        $payment = $this->pay($cashier, $this->order());
        Carbon::setTestNow('2026-10-04 11:30:00');

        // Act
        $response = $this->review($reviewer, $payment);

        // Assert
        $response->assertOk()
            ->assertJsonPath('message', 'تمت مراجعة الدفعة')
            ->assertJsonPath('data.payment.is_reviewed', true)
            ->assertJsonPath('data.payment.reviewer.id', $checker->id)
            ->assertJsonPath('data.payment.reviewer.name', $checker->name)
            ->assertJsonPath('data.payment.can_review', false)
            ->assertJsonPath('data.payment.can_unreview', true);

        $payment->refresh();
        $this->assertSame((int) $checker->id, (int) $payment->reviewed_by);
        $this->assertTrue($payment->reviewed_at->equalTo(Carbon::parse('2026-10-04 11:30:00')));
    }

    public function test_the_person_who_recorded_the_entry_may_review_it_with_the_grant(): void
    {
        // Arrange — the owner's choice (2026-10-04): no second person is demanded.
        [$counter, $cashier] = $this->cashier();
        $payment = $this->pay($cashier, $this->order());

        // Act
        $response = $this->review($cashier, $payment);

        // Assert — and the stamp says so, beside who recorded it.
        $response->assertOk()
            ->assertJsonPath('data.payment.is_reviewed', true)
            ->assertJsonPath('data.payment.reviewer.id', $counter->id)
            ->assertJsonPath('data.payment.recorded_by', $counter->id);
    }

    public function test_an_administrator_reviews_without_being_granted_it(): void
    {
        // Arrange — administrators reach every grant through `Gate::before`.
        [, $cashier] = $this->cashier();
        $admin = User::factory()->create();
        $admin->assignRole(Role::findOrCreate(RoleName::Admin->value, 'web'));
        $payment = $this->pay($cashier, $this->order());

        // Act
        $response = $this->review(['Authorization' => 'Bearer '.$admin->createToken('test')->plainTextToken], $payment);

        // Assert
        $response->assertOk()->assertJsonPath('data.payment.reviewer.id', $admin->id);
    }

    public function test_the_ledger_tells_each_person_whether_they_may_review_before_they_tap(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        [, $viewer] = $this->userWith([PermissionName::ViewOrders, PermissionName::ViewOrderPayments]);
        $order = $this->order();
        $this->pay($cashier, $order);
        $url = "/api/v1/orders/{$order->id}/payments";

        // Act
        $asRecorder = $this->withHeaders($cashier)->getJson($url);
        $asReviewer = $this->withHeaders($reviewer)->getJson($url);
        $asViewer = $this->withHeaders($viewer)->getJson($url);

        // Assert
        $asRecorder->assertOk()
            ->assertJsonPath('data.payments.0.requires_review', true)
            ->assertJsonPath('data.payments.0.is_reviewed', false)
            ->assertJsonPath('data.payments.0.can_review', true)
            ->assertJsonPath('data.payments.0.review_blocked_reason', null);
        $asReviewer->assertOk()
            ->assertJsonPath('data.payments.0.can_review', true)
            ->assertJsonPath('data.payments.0.review_blocked_reason', null);
        // Without the grant there is no button to grey, so there is no reason to give.
        $asViewer->assertOk()
            ->assertJsonPath('data.payments.0.can_review', false)
            ->assertJsonPath('data.payments.0.can_unreview', false)
            ->assertJsonPath('data.payments.0.review_blocked_reason', null);
    }

    public function test_the_recorder_may_still_take_a_review_back(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $payment = $this->pay($cashier, $this->order());
        $this->review($reviewer, $payment)->assertOk();

        // Act
        $response = $this->review($cashier, $payment, reviewed: false);

        // Assert
        $response->assertOk()
            ->assertJsonPath('message', 'أُلغيت مراجعة الدفعة')
            ->assertJsonPath('data.payment.is_reviewed', false)
            ->assertJsonPath('data.payment.reviewer', null);
        $this->assertNull($payment->fresh()->reviewed_at);
        $this->assertNull($payment->fresh()->reviewed_by);
    }

    public function test_reviewing_twice_keeps_the_first_review(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [$first, $firstHeaders] = $this->reviewer();
        [, $secondHeaders] = $this->reviewer();
        $payment = $this->pay($cashier, $this->order());
        Carbon::setTestNow('2026-10-04 09:00:00');
        $this->review($firstHeaders, $payment)->assertOk();
        Carbon::setTestNow('2026-10-04 15:00:00');

        // Act
        $response = $this->review($secondHeaders, $payment);

        // Assert
        $response->assertOk()->assertJsonPath('data.payment.reviewer.id', $first->id);
        $this->assertTrue($payment->fresh()->reviewed_at->equalTo(Carbon::parse('2026-10-04 09:00:00')));
    }

    public function test_an_entry_nobody_signed_may_be_reviewed_by_anybody(): void
    {
        // Arrange — what a Nawris webhook writes: a payment with no person behind it.
        [, $reviewer] = $this->reviewer();
        $order = $this->order();
        $payment = app(RecordOrderPayment::class)($order, OrderPaymentData::fromArray([
            'amount' => '100.00',
            'method' => PaymentMethod::Cash->value,
        ]));

        // Act
        $response = $this->review($reviewer, $payment);

        // Assert
        $this->assertTrue($payment->requires_review);
        $this->assertNull($payment->recorded_by);
        $response->assertOk()->assertJsonPath('data.payment.is_reviewed', true);
    }

    public function test_a_reversed_payment_has_nothing_left_to_review(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $order = $this->order();
        $payment = $this->pay($cashier, $order);
        $this->withHeaders($cashier)
            ->postJson("/api/v1/orders/{$order->id}/payments/{$payment->id}/reverse", ['reason' => 'خطأ'])
            ->assertCreated();

        // Act
        $response = $this->review($reviewer, $payment);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('message', 'الدفعة ملغاة — لا شيء فيها يُراجع');
        $this->queue($reviewer)->assertOk()->assertJsonPath('meta.total', 0);
    }

    public function test_a_review_moves_no_money(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $order = $this->order();
        $payment = $this->pay($cashier, $order, ['amount' => '150.00']);
        $movements = TreasuryMovement::query()->count();

        // Act
        $this->review($reviewer, $payment)->assertOk();
        $this->review($reviewer, $payment, reviewed: false)->assertOk();

        // Assert
        $this->assertSame('150.00', (string) $payment->fresh()->amount);
        $this->assertSame('150.00', (string) $order->fresh()->paid_amount);
        $this->assertSame($movements, TreasuryMovement::query()->count());
    }

    public function test_reviewing_costs_its_own_grant(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $payer] = $this->userWith([PermissionName::ViewOrderPayments, PermissionName::RecordOrderPayments]);
        $payment = $this->pay($cashier, $this->order());

        // Act
        $review = $this->review($payer, $payment);
        $queue = $this->queue($payer);

        // Assert
        $review->assertForbidden();
        $queue->assertForbidden();
    }

    public function test_another_orders_payment_is_not_found_under_this_order(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $payment = $this->pay($cashier, $this->order());
        $other = $this->order();

        // Act
        $response = $this->withHeaders($reviewer)
            ->patchJson("/api/v1/orders/{$other->id}/payments/{$payment->id}/review", ['reviewed' => true]);

        // Assert
        $response->assertNotFound();
    }

    public function test_the_answer_must_be_given(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $payment = $this->pay($cashier, $this->order());

        // Act
        $response = $this->withHeaders($reviewer)
            ->patchJson("/api/v1/orders/{$payment->order_id}/payments/{$payment->id}/review", []);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['reviewed']);
        $this->assertNull($payment->fresh()->reviewed_at);
    }

    // ── on the treasury's account page ──────────────────────────────────────────────────

    public function test_the_account_ledger_line_says_whether_its_payment_was_reviewed(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [$checker, $reviewer] = $this->reviewer();
        [, $treasurer] = $this->userWith([PermissionName::ViewTreasury]);
        $payment = $this->pay($cashier, $this->order());
        $url = "/api/v1/treasury/accounts/{$payment->treasury_account_id}/movements";

        // Act
        $before = $this->withHeaders($treasurer)->getJson($url);
        $this->review($reviewer, $payment)->assertOk();
        $after = $this->withHeaders($treasurer)->getJson($url);

        // Assert
        $before->assertOk()
            ->assertJsonPath('data.0.source_id', $payment->id)
            ->assertJsonPath('data.0.payment_review.is_reviewed', false)
            ->assertJsonPath('data.0.payment_review.reviewer', null);
        $after->assertOk()
            ->assertJsonPath('data.0.payment_review.is_reviewed', true)
            ->assertJsonPath('data.0.payment_review.reviewer.name', $checker->name);
    }

    public function test_a_line_from_a_payment_exempt_from_review_carries_no_badge(): void
    {
        // Arrange — a hand deposit is not a customer's payment at all.
        [, $treasurer] = $this->userWith([PermissionName::ViewTreasury, PermissionName::RecordTreasuryOperations]);
        $cash = TreasuryAccount::query()
            ->where('kind', 'cash')->where('is_default', true)->firstOrFail();
        $this->withHeaders($treasurer)->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $cash->id,
            'amount' => '50.00',
        ])->assertCreated();

        // Act
        $response = $this->withHeaders($treasurer)->getJson("/api/v1/treasury/accounts/{$cash->id}/movements");

        // Assert
        $response->assertOk()->assertJsonMissingPath('data.0.payment_review');
    }

    // ── the queue ───────────────────────────────────────────────────────────────────────

    public function test_the_queue_lists_what_waits_oldest_first_with_its_order(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $order = $this->order();
        $later = $this->pay($cashier, $order, ['amount' => '60.00', 'paid_at' => '2026-10-02 10:00:00']);
        $earlier = $this->pay($cashier, $order, ['amount' => '40.00', 'paid_at' => '2026-10-01 10:00:00']);
        $done = $this->pay($cashier, $order, ['amount' => '30.00']);
        $this->review($reviewer, $done)->assertOk();

        // Act
        $response = $this->queue($reviewer);

        // Assert
        $response->assertOk()
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('data.0.id', $earlier->id)
            ->assertJsonPath('data.1.id', $later->id)
            ->assertJsonPath('data.0.order.id', $order->id)
            ->assertJsonPath('data.0.order.code', $order->code)
            ->assertJsonPath('data.0.can_review', true);
    }

    public function test_the_queue_adds_money_in_and_money_out_apart(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $order = $this->order();
        $this->pay($cashier, $order, ['amount' => '300.00']);
        $this->withHeaders($cashier)->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
            'amount' => '75.00',
            'method' => PaymentMethod::Cash->value,
        ])->assertCreated();

        // Act
        $all = $this->queue($reviewer);
        $refunds = $this->queue($reviewer, ['type' => OrderPaymentType::Refund->value]);

        // Assert
        $all->assertOk()
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('meta.incoming_total', '300.00')
            ->assertJsonPath('meta.outgoing_total', '75.00');
        $refunds->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.type', OrderPaymentType::Refund->value)
            ->assertJsonPath('meta.incoming_total', '0.00');
    }

    public function test_the_queue_filters_by_day_and_by_who_recorded(): void
    {
        // Arrange
        [$counterOne, $one] = $this->cashier();
        [, $two] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $order = $this->order();
        $this->pay($one, $order, ['paid_at' => '2026-10-01 10:00:00']);
        $this->pay($two, $order, ['paid_at' => '2026-10-03 10:00:00']);

        // Act
        $byDay = $this->queue($reviewer, ['from' => '2026-10-02', 'to' => '2026-10-03']);
        $byRecorder = $this->queue($reviewer, ['recorded_by' => $counterOne->id]);

        // Assert
        $byDay->assertOk()->assertJsonPath('meta.total', 1);
        $byRecorder->assertOk()->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.recorded_by', $counterOne->id);
    }

    public function test_a_deleted_orders_entries_leave_the_queue(): void
    {
        // Arrange
        [, $cashier] = $this->cashier();
        [, $reviewer] = $this->reviewer();
        $order = $this->order();
        $this->pay($cashier, $order);

        // Act
        $order->delete();

        // Assert
        $this->queue($reviewer)->assertOk()->assertJsonPath('meta.total', 0);
    }
}
