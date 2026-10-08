<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\DeleteOrder;
use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Enums\PaymentStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «الزائد إيراد» — زبونٌ دفع ١٠٠ على طلبيةٍ بـ٩٩ لأنّ أحداً لا يملك الدينار.
 *
 * **ما تُلزم به المجموعةُ الميزة** (قرار صاحب العمل ٢٠٢٦-١٠-٠٧: «ديمة اعتبره إيراد، لا حاجة لزر
 * الإيراد»): الدفعةُ تُؤخذ كاملةً قيداً واحداً وبعد تأكيدٍ فقط؛ الطلبيةُ مدفوعةٌ ٩٩ ومبيعاتُها ٩٩؛
 * والدينارُ للمحلّ من ساعته — لا يُكتب على الطلبية زائداً للزبون، ولا على «علينا»، ولا زرَّ يقرّره.
 *
 * See Docs/payments/PAYMENT-REVIEW-AND-OVERPAY.md. Arrange - Act - Assert throughout.
 */
class OrderOverpaymentTest extends TestCase
{
    use RefreshDatabase;

    private const RETIRE_KEEP_EXCESS = '2026_10_08_100100_retire_keep_excess_permission';

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

    private function nothingIsOwedToCustomers(): void
    {
        $this->assertFalse(
            TreasuryAccount::query()->where('system_code', TreasuryAccount::CUSTOMER_EXCESS)->exists(),
            '«مبالغ زائدة للزبائن» لا يُفتح: الزائد ليس ديناً على المحل',
        );
        $this->assertSame(0, TreasuryMovement::query()->where('kind', MovementKind::CustomerExcess->value)->count());
    }

    // ── أخذُه ────────────────────────────────────────────────────────────────────────────

    public function test_more_than_is_owed_is_refused_until_somebody_confirms_it(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');

        // Act
        $response = $this->pay($headers, $order, ['amount' => '100.00']);

        // Assert — التأكيدُ هو ما يزال يلتقط ٥٠٠ كُتبت مكان ٥٠.
        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['amount'])
            ->assertJsonPath('message', 'المبلغ (100.00) أكبر من المتبقي على الطلبية (99.00) — أكّد تسجيل الزائد إيراداً');
        $this->assertSame(0, OrderPayment::query()->count());
    }

    public function test_a_confirmed_overpayment_is_one_entry_and_the_excess_is_the_shops_at_once(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');

        // Act
        $response = $this->pay($headers, $order, ['amount' => '100.00', 'accept_overpayment' => true]);

        // Assert — الدفعةُ تحمل ما زاد منها، والطلبيةُ لا تحمل زائداً لأحد.
        $response->assertCreated()
            ->assertJsonPath('data.payment.amount', '100.00')
            ->assertJsonPath('data.payment.excess_amount', '1.00')
            ->assertJsonPath('data.summary.paid_amount', '99.00')
            ->assertJsonPath('data.summary.excess_amount', '0.00')
            ->assertJsonPath('data.summary.remaining_amount', '0.00')
            ->assertJsonPath('data.summary.payment_status', PaymentStatus::Paid->value);

        $order->refresh();
        $this->assertSame('99.00', (string) $order->grand_total, 'المبيعات لم تتغيّر');
        $this->assertSame('99.00', (string) $order->paid_amount);
        $this->assertSame('0.00', (string) $order->excess_amount);
        $this->assertSame(1, OrderPayment::query()->where('order_id', $order->id)->count());
    }

    public function test_the_drawer_holds_all_of_it_and_nothing_is_owed_to_the_customer(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $before = $this->balance($this->cashBox());

        // Act
        $this->overpay($headers, $order);

        // Assert — ١٠٠ في الدُّرج، ولا شيء على «علينا».
        $this->assertSame(bcadd($before, '100.00', 2), $this->balance($this->cashBox()));
        $this->nothingIsOwedToCustomers();
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
        $this->assertSame('0.00', (string) $order->fresh()->excess_amount);
    }

    public function test_a_payload_cannot_name_its_own_excess(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');

        // Act
        $response = $this->pay($headers, $order, ['amount' => '50.00', 'excess_amount' => '40.00']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.payment.excess_amount', '0.00')
            ->assertJsonPath('data.summary.paid_amount', '50.00');
    }

    // ── الردّ ────────────────────────────────────────────────────────────────────────────

    public function test_a_refund_comes_off_what_the_order_was_paid(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->overpay($headers, $order);

        // Act
        $response = $this->refund($headers, $order, ['amount' => '1.00']);

        // Assert — الزائدُ صار للمحل، فلا زائدَ يُردّ منه: الردُّ ينقص المدفوع.
        $response->assertCreated()
            ->assertJsonPath('data.payment.excess_amount', '0.00')
            ->assertJsonPath('data.summary.paid_amount', '98.00')
            ->assertJsonPath('data.summary.remaining_amount', '1.00');
        $this->nothingIsOwedToCustomers();
    }

    public function test_a_refund_may_reach_what_was_paid_and_no_further(): void
    {
        // Arrange
        $headers = $this->cashier();
        $order = $this->order('99.00');
        $this->overpay($headers, $order);

        // Act
        $tooMuch = $this->refund($headers, $order, ['amount' => '99.01']);
        $all = $this->refund($headers, $order, ['amount' => '99.00']);

        // Assert
        $tooMuch->assertUnprocessable();
        $all->assertCreated()->assertJsonPath('data.summary.paid_amount', '0.00');
    }

    // ── لا زرَّ ولا صلاحية ───────────────────────────────────────────────────────────────

    public function test_there_is_no_door_for_keeping_the_excess(): void
    {
        // Arrange
        $headers = $this->auth([PermissionName::RecordOrderPayments, PermissionName::ReverseOrderPayments]);
        $order = $this->order('99.00');

        // Act
        $response = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/keep-excess");

        // Assert
        $this->assertFalse(Route::has('orders.payments.keep-excess'));
        $this->assertContains($response->status(), [404, 405]);
        $this->assertNull(PermissionName::tryFrom('orders.payments.keep_excess'));
    }

    public function test_the_retired_grant_leaves_the_roles_that_held_it(): void
    {
        // Arrange — قاعدةٌ شغّلت ترحيل ٤ أكتوبر، ودورٌ أُعطيها.
        $retired = Permission::findOrCreate('orders.payments.keep_excess', 'web');
        $role = Role::findOrCreate(RoleName::Accountant->value, 'web');
        $role->givePermissionTo($retired);

        // Act
        (require database_path('migrations/'.self::RETIRE_KEEP_EXCESS.'.php'))->up();

        // Assert
        $this->assertFalse(Permission::query()->where('name', 'orders.payments.keep_excess')->exists());
        $this->assertFalse($role->fresh()->load('permissions')->permissions->contains('name', 'orders.payments.keep_excess'));
    }

    // ── التراجع ──────────────────────────────────────────────────────────────────────────

    public function test_reversing_an_overpayment_takes_back_all_the_cash(): void
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
    }

    public function test_deleting_the_order_undoes_the_overpayment(): void
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
        $before = $this->balance($this->cashBox());
        $this->overpay($headers, $order);

        // Act
        $deleted = app(DeleteOrder::class)($order->refresh(), User::factory()->create());

        // Assert
        $this->assertSame('0.00', (string) $deleted->paid_amount);
        $this->assertSame('0.00', (string) $deleted->excess_amount);
        $this->assertSame($before, $this->balance($this->cashBox()));
    }

    // ── عند التسليم، في شاشة الحالة ──────────────────────────────────────────────────────

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
        $this->assertSame('المبلغ يزيد على المتبقي — يُسجَّل الزائد إيراداً', $confirm['label']);
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
        $this->assertSame('0.00', (string) $order->excess_amount);
        $this->assertSame('1.00', (string) $order->payments()->sole()->excess_amount);
    }

    // ── حسابُ الزائد القديم ما زال للطلبيات وحدها ─────────────────────────────────────────

    public function test_nobody_moves_what_customers_are_owed_by_hand(): void
    {
        // Arrange — حسابٌ فُتح قبل القرار ما زال في القواعد التي فتحته.
        $payable = app(TreasuryService::class)->customerExcessPayable();
        $headers = $this->auth([PermissionName::ViewTreasury, PermissionName::RecordTreasuryOperations]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer',
            'from_account_id' => $this->cashBox()->id,
            'to_account_id' => $payable->id,
            'amount' => '1.00',
        ]);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('0.00', $this->balance($payable));
    }
}
