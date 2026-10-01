<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «خزنة مكتب الاستلام» — cash taken while an order waits at a branch lands in that branch's box.
 * TREASURY-DESIGN §١٩.
 *
 * Arrange - Act - Assert throughout.
 */
class PickupOfficeBoxTest extends TestCase
{
    use RefreshDatabase;

    private City $misrata;

    private TreasuryAccount $misrataBox;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Storage::fake('local');

        $this->misrata = City::factory()->officePickup()->create(['name' => 'استلام مكتب مصراتة']);
        $this->misrataBox = TreasuryAccount::factory()->kind(AccountKind::Cash)->create(['name' => 'خزنة فرع مصراتة']);
        $this->misrataBox->forceFill(['pickup_city_id' => $this->misrata->id])->save();
    }

    /**
     * @return array{0: User, 1: array<string, string>}
     */
    private function clerk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewOrders,
            PermissionName::MarkOrdersDelivered,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ViewTreasury,
            PermissionName::ManageTreasury,
        ]));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    private function atTheBranch(OrderStatus $status = OrderStatus::OfficePickup): Order
    {
        return Order::factory()->create([
            'status' => $status,
            'fulfilment_type' => FulfilmentType::OfficePickup,
            'city_id' => $this->misrata->id,
            'items_total' => '200.00',
            'delivery_price' => '0.00',
            'grand_total' => '200.00',
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $fields
     */
    private function collected(array $headers, Order $order, array $fields): TestResponse
    {
        return $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => $fields,
        ]);
    }

    // ── where the cash lands ────────────────────────────────────────────────────────────

    public function test_cash_taken_when_the_customer_collects_lands_in_the_branch_box(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $order = $this->atTheBranch();

        // Act
        $response = $this->collected($headers, $order, ['payment_amount' => '200', 'payment_method' => 'cash']);

        // Assert
        $response->assertOk();
        $this->assertSame('200.00', $this->balance($this->misrataBox));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_the_branch_box_comes_before_the_clerks_own_cash_account(): void
    {
        // Arrange — the clerk holds a cash account of their own, and «الحساب الشخصي أولاً» is on
        [$clerk, $headers] = $this->clerk();
        $own = TreasuryAccount::factory()->kind(AccountKind::Cash)->heldBy($clerk)->create();
        $order = $this->atTheBranch();

        // Act
        $this->collected($headers, $order, ['payment_amount' => '200', 'payment_method' => 'cash'])->assertOk();

        // Assert
        $this->assertSame('200.00', $this->balance($this->misrataBox));
        $this->assertSame('0.00', $this->balance($own));
    }

    public function test_a_card_at_the_branch_still_lands_in_the_bank(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $order = $this->atTheBranch();

        // Act
        $this->collected($headers, $order, ['payment_amount' => '200', 'payment_method' => 'bank_card'])->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($this->misrataBox));
        $this->assertSame('200.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_an_account_picked_by_hand_still_wins(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $order = $this->atTheBranch();

        // Act
        $this->collected($headers, $order, [
            'payment_amount' => '200',
            'payment_method' => 'cash',
            'payment_account_id' => (string) $this->defaultOf(AccountKind::Cash)->id,
        ])->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($this->misrataBox));
        $this->assertSame('200.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_the_payments_screen_uses_the_box_only_while_the_order_waits_at_the_branch(): void
    {
        // Arrange — one waiting at the branch, one still in the workshop
        [, $headers] = $this->clerk();
        $waiting = $this->atTheBranch();
        $inTheWorkshop = $this->atTheBranch(OrderStatus::Printing);

        // Act
        $this->withHeaders($headers)->post("/api/v1/orders/{$waiting->id}/payments", ['amount' => '50', 'method' => 'cash'])->assertCreated();
        $this->withHeaders($headers)->post("/api/v1/orders/{$inTheWorkshop->id}/payments", ['amount' => '30', 'method' => 'cash'])->assertCreated();

        // Assert — a payment before the order reaches the counter is head office's cash
        $this->assertSame('50.00', $this->balance($this->misrataBox));
        $this->assertSame('30.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame((int) $this->misrataBox->id, (int) OrderPayment::query()->where('order_id', $waiting->id)->sole()->treasury_account_id);
    }

    public function test_the_picker_names_the_branch_box_as_automatic_for_that_order(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $order = $this->atTheBranch();

        // Act
        $forTheOrder = $this->getJson("/api/v1/treasury/account-options?method=cash&order_id={$order->id}", $headers);
        $forNoOrder = $this->getJson('/api/v1/treasury/account-options?method=cash', $headers);

        // Assert
        $forTheOrder->assertOk()->assertJsonPath('data.suggested_id', $this->misrataBox->id);
        $forNoOrder->assertOk()->assertJsonPath('data.suggested_id', $this->defaultOf(AccountKind::Cash)->id);
    }

    public function test_money_going_out_at_the_branch_is_not_named_after_the_branch_box(): void
    {
        // Arrange — الردُّ لا يُصرف من صندوق الفرع، فلا يسمّيه «تلقائي»
        [, $headers] = $this->clerk();
        $order = $this->atTheBranch();

        // Act
        $response = $this->getJson("/api/v1/treasury/account-options?method=cash&purpose=out&order_id={$order->id}", $headers);

        // Assert — يسمّي ما سيُصرف منه فعلاً
        $response->assertOk()
            ->assertJsonPath('data.suggested_id', $this->defaultOf(AccountKind::Cash)->id)
            ->assertJsonPath('data.suggested_name', $this->defaultOf(AccountKind::Cash)->name);
    }

    // ── linking a box ───────────────────────────────────────────────────────────────────

    public function test_the_settings_list_each_branch_with_its_box(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $tripoli = City::factory()->officePickup()->create(['name' => 'استلام مكتب طرابلس']);

        // Act
        $response = $this->getJson('/api/v1/treasury/settings', $headers);

        // Assert
        $offices = collect($response->assertOk()->json('data.pickup_offices'))->keyBy('city_id');
        $this->assertSame($this->misrataBox->id, $offices[$this->misrata->id]['account_id']);
        $this->assertSame('خزنة فرع مصراتة', $offices[$this->misrata->id]['account_name']);
        $this->assertNull($offices[$tripoli->id]['account_id']);
    }

    public function test_linking_a_new_box_to_a_branch_unlinks_the_old_one(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $newBox = TreasuryAccount::factory()->kind(AccountKind::Cash)->create(['name' => 'خزنة مصراتة الجديدة']);

        // Act
        $response = $this->putJson("/api/v1/treasury/accounts/{$newBox->id}", [
            'name' => $newBox->name,
            'pickup_city_id' => $this->misrata->id,
        ], $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.pickup_city_id', $this->misrata->id);
        $this->assertNull($this->misrataBox->fresh()->pickup_city_id);
    }

    public function test_only_a_cash_account_and_only_a_pickup_branch_may_be_linked(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $bank = $this->defaultOf(AccountKind::Bank);
        $deliveryCity = City::factory()->create();
        $box = TreasuryAccount::factory()->kind(AccountKind::Cash)->create();

        // Act
        $bankLinked = $this->putJson("/api/v1/treasury/accounts/{$bank->id}", [
            'name' => $bank->name,
            'pickup_city_id' => $this->misrata->id,
        ], $headers);
        $notABranch = $this->putJson("/api/v1/treasury/accounts/{$box->id}", [
            'name' => $box->name,
            'pickup_city_id' => $deliveryCity->id,
        ], $headers);

        // Assert
        $bankLinked->assertUnprocessable()->assertJsonValidationErrors('pickup_city_id');
        $notABranch->assertUnprocessable()->assertJsonValidationErrors('pickup_city_id');
        $this->assertSame((int) $this->misrata->id, (int) $this->misrataBox->fresh()->pickup_city_id);
    }
}
