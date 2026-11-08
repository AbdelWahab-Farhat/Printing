<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * خياراتُ الفلتر في «مراجعة وتسوية الدفعات»: أزرار «نوع الدفعة»، والحسابات، والموظفون.
 *
 * **أسماءٌ لا أرصدة، ولحامل إحدى الصلاحيتين**: مَن يراجع ولا يسوّي يحتاج القوائم نفسها، وقد كانت
 * الحسابات خلف صلاحية التسوية والموظفون خلف `users.view`.
 *
 * Arrange - Act - Assert throughout.
 */
class PaymentFilterOptionsTest extends TestCase
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
     * @param  array<string, string>  $headers
     */
    private function filterOptions(array $headers): TestResponse
    {
        return $this->getJson('/api/v1/order-payments/filter-options', $headers);
    }

    /**
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

    private function order(): Order
    {
        return Order::factory()->create([
            'items_total' => '450.00',
            'delivery_price' => '0.00',
            'grand_total' => '450.00',
            'status' => OrderStatus::Ready,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function pay(array $headers, Order $order, string $method): int
    {
        return (int) $this->postJson(
            "/api/v1/orders/{$order->id}/payments",
            ['amount' => '100.00', 'method' => $method],
            $headers,
        )->assertCreated()->json('data.payment.id');
    }

    private function account(string $name): TreasuryAccount
    {
        return TreasuryAccount::query()->where('name', $name)->firstOrFail();
    }

    private function onOffice(TreasuryAccount $account, string $city): void
    {
        $account->forceFill(['pickup_city_id' => City::factory()->create(['name' => $city])->id])->save();
    }

    public function test_a_reviewer_and_a_settler_may_read_them_and_nobody_else(): void
    {
        // Arrange
        [, $reviewer] = $this->userWith([PermissionName::ReviewOrderPayments]);
        [, $settler] = $this->userWith([PermissionName::SettleOrderPayments]);
        [, $stranger] = $this->userWith([PermissionName::ViewOrders]);

        // Act
        $byReviewer = $this->filterOptions($reviewer);
        $bySettler = $this->filterOptions($settler);
        $byStranger = $this->filterOptions($stranger);

        // Assert
        $byReviewer->assertOk();
        $bySettler->assertOk();
        $byStranger->assertForbidden();
    }

    public function test_the_kinds_are_the_transfer_nawris_each_office_libyana_and_the_card(): void
    {
        // Arrange — كاشُ كل مكتب اسمُه من مكتبه، لا من الحساب.
        [, $headers] = $this->userWith([PermissionName::ReviewOrderPayments]);
        $gurji = $this->account('بريمولا قرجي');
        $waliAlAhd = $this->account('بريمولا ولي العهد');
        $this->onOffice($gurji, 'إستلام مكتب(قرجي)');
        $this->onOffice($waliAlAhd, 'إستلام مكتب(ولي العهد)');
        $nawris = TreasuryAccount::query()->where('system_code', TreasuryAccount::NAWRIS)->firstOrFail();

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $response->assertOk();
        $this->assertSame([
            ['label' => 'حوالة', 'method' => 'bank_transfer', 'account_id' => null],
            ['label' => 'كاش نورس', 'method' => null, 'account_id' => $nawris->id],
            ['label' => 'مكتب قرجي', 'method' => null, 'account_id' => $gurji->id],
            ['label' => 'مكتب ولي العهد', 'method' => null, 'account_id' => $waliAlAhd->id],
            ['label' => 'ليبيانا', 'method' => 'libyana', 'account_id' => null],
            ['label' => 'بطاقة مصرفية', 'method' => 'bank_card', 'account_id' => null],
        ], $response->json('data.kinds'));
    }

    public function test_the_kinds_come_most_used_first_and_a_tie_keeps_the_shops_order(): void
    {
        // Arrange — ليبيانا مرّتان، وكاشُ قرجي مرّة، والبقية بلا استعمال.
        [, $headers] = $this->cashier();
        $this->onOffice($this->account('بريمولا قرجي'), 'إستلام مكتب(قرجي)');
        $this->onOffice($this->account('بريمولا ولي العهد'), 'إستلام مكتب(ولي العهد)');
        $order = $this->order();
        $this->pay($headers, $order, 'libyana');
        $this->pay($headers, $order, 'libyana');
        $this->pay($headers, $order, 'cash');

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $this->assertSame(
            ['ليبيانا', 'مكتب قرجي', 'حوالة', 'كاش نورس', 'مكتب ولي العهد', 'بطاقة مصرفية'],
            array_column($response->json('data.kinds'), 'label'),
        );
    }

    public function test_a_cancelled_payment_does_not_count_as_use(): void
    {
        // Arrange — ليبيانا مرّتان ثم أُلغيتا: قيدان لم يحصلا، فكاشُ قرجي يتقدّم عليها.
        [, $headers] = $this->cashier();
        $this->onOffice($this->account('بريمولا قرجي'), 'إستلام مكتب(قرجي)');
        $order = $this->order();
        foreach ([$this->pay($headers, $order, 'libyana'), $this->pay($headers, $order, 'libyana')] as $id) {
            $this->postJson("/api/v1/orders/{$order->id}/payments/{$id}/reverse", ['reason' => 'سُجّلت بالخطأ'], $headers)
                ->assertSuccessful();
        }
        $this->pay($headers, $order, 'cash');

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $this->assertSame('مكتب قرجي', $response->json('data.kinds.0.label'));
    }

    public function test_an_old_payment_with_no_account_does_not_count_as_use(): void
    {
        // Arrange — حوالتان من قبل الحسابات، وكاشٌ بعدها في قرجي: القديم يعرف طريقته ولا يعرف مكتبه.
        [, $headers] = $this->cashier();
        $this->onOffice($this->account('بريمولا قرجي'), 'إستلام مكتب(قرجي)');
        $order = $this->order();
        // The check lets an account-less payment through only for rows older than the migration.
        DB::statement('ALTER TABLE order_payments DROP CONSTRAINT order_payments_money_names_an_account');
        OrderPayment::factory()->count(2)->forOrder($order)->bankTransfer()->create([
            'treasury_account_id' => null,
        ]);
        $this->pay($headers, $order, 'cash');

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $this->assertSame('مكتب قرجي', $response->json('data.kinds.0.label'));
    }

    public function test_a_cash_account_with_no_office_is_no_button_but_stays_an_account(): void
    {
        // Arrange — حساباتُ الموظفين كثيرة، فتبقى في «حساب آخر» ولا تملأ الورقة أزراراً.
        [, $headers] = $this->userWith([PermissionName::ReviewOrderPayments]);
        $box = TreasuryAccount::factory()->kind(AccountKind::Cash)->create(['name' => 'صندوق المعرض']);

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $this->assertNotContains($box->id, array_column($response->json('data.kinds'), 'account_id'));
        $this->assertContains($box->id, array_column($response->json('data.accounts'), 'id'));
    }

    public function test_an_office_named_another_way_goes_by_its_accounts_name(): void
    {
        // Arrange
        [, $headers] = $this->userWith([PermissionName::ReviewOrderPayments]);
        $box = TreasuryAccount::factory()->kind(AccountKind::Cash)->create(['name' => 'كاش الزاوية']);
        $this->onOffice($box, 'الزاوية');

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $this->assertContains(
            ['label' => 'كاش الزاوية', 'method' => null, 'account_id' => $box->id],
            $response->json('data.kinds'),
        );
    }

    public function test_a_closed_office_is_no_button(): void
    {
        // Arrange
        [, $headers] = $this->userWith([PermissionName::ReviewOrderPayments]);
        $closed = TreasuryAccount::factory()->kind(AccountKind::Cash)->create(['name' => 'مكتب مغلق', 'is_active' => false]);
        $this->onOffice($closed, 'إستلام مكتب(القديم)');

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $this->assertNotContains($closed->id, array_column($response->json('data.kinds'), 'account_id'));
        $this->assertContains($closed->id, array_column($response->json('data.accounts'), 'id'));
    }

    public function test_the_accounts_are_names_of_every_place_a_payment_can_sit(): void
    {
        // Arrange
        [, $headers] = $this->userWith([PermissionName::ReviewOrderPayments]);
        $bank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'مصرف علي']);

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $accounts = collect($response->json('data.accounts'));
        $this->assertTrue($accounts->pluck('id')->contains($bank->id));
        $this->assertSame(['id', 'name', 'kind'], array_keys($accounts->firstOrFail()));
    }

    public function test_the_people_are_who_recorded_and_who_settled_by_name_alone(): void
    {
        // Arrange — موظفٌ سجّل، وآخر سوّى، وثالثٌ لم يفعل شيئاً.
        [$clerk, $clerkHeaders] = $this->userWith([
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
        ]);
        [$settler, $settlerHeaders] = $this->userWith([PermissionName::SettleOrderPayments]);
        [$idle, $idleHeaders] = $this->userWith([PermissionName::ReviewOrderPayments]);
        $order = Order::factory()->create([
            'items_total' => '450.00',
            'delivery_price' => '0.00',
            'grand_total' => '450.00',
            'status' => OrderStatus::Ready,
        ]);
        $paymentId = $this->postJson(
            "/api/v1/orders/{$order->id}/payments",
            ['amount' => '100.00', 'method' => 'cash'],
            $clerkHeaders,
        )->assertCreated()->json('data.payment.id');
        $bank = TreasuryAccount::query()->where('kind', AccountKind::Bank->value)->where('is_default', true)->firstOrFail();
        $this->postJson(
            '/api/v1/order-payments/settle',
            ['payments' => [['payment_id' => $paymentId]], 'account_id' => $bank->id],
            $settlerHeaders,
        )->assertOk();

        // Act
        $response = $this->filterOptions($idleHeaders);

        // Assert
        $response->assertOk();
        $this->assertSame([['id' => $clerk->id, 'name' => $clerk->name]], $response->json('data.recorders'));
        $this->assertSame([['id' => $settler->id, 'name' => $settler->name]], $response->json('data.settlers'));
        $this->assertNotContains($idle->id, array_column($response->json('data.recorders'), 'id'));
    }

    public function test_somebody_who_left_stays_on_the_list_their_entries_are_on(): void
    {
        // Arrange — موظفٌ سجّل ثم حُذف: دفعاته باقيةٌ في القائمتين، فلا بدّ أن يبقى اسمه.
        [$clerk, $clerkHeaders] = $this->userWith([
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
        ]);
        [, $headers] = $this->userWith([PermissionName::ReviewOrderPayments]);
        $order = Order::factory()->create([
            'items_total' => '450.00',
            'delivery_price' => '0.00',
            'grand_total' => '450.00',
            'status' => OrderStatus::Ready,
        ]);
        $this->postJson(
            "/api/v1/orders/{$order->id}/payments",
            ['amount' => '100.00', 'method' => 'cash'],
            $clerkHeaders,
        )->assertCreated();
        $clerk->delete();

        // Act
        $response = $this->filterOptions($headers);

        // Assert
        $this->assertContains($clerk->id, array_column($response->json('data.recorders'), 'id'));
    }
}
