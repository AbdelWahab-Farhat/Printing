<?php

declare(strict_types=1);

namespace Tests\Feature\InstantOrders;

use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Enums\MovementType;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\Support\SellsAtTheCounter;
use Tests\TestCase;

/**
 * Handing over, cancelling and settling an instant order — INSTANT-ORDERS-PLAN.md §5–§7.
 */
class InstantOrderHandoverTest extends TestCase
{
    use RefreshDatabase;
    use SellsAtTheCounter;

    protected function setUp(): void
    {
        parent::setUp();

        $this->registerPermissions();
    }

    /** @return array{0: City, 1: User, 2: Order, 3: array{cash: TreasuryAccount, bank: TreasuryAccount}, 4: ProductVariant} */
    private function soldFifteenKilos(): array
    {
        $branch = $this->counterBranch();
        $accounts = $this->branchAccounts($branch);
        [$product, $variant] = $this->plainProduct('10.000');
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);

        return [$branch, $employee, $this->takeInstantOrder($branch, $employee, $product, $variant, 15), $accounts, $variant];
    }

    public function test_a_new_instant_order_offers_handover_and_cancel_and_nothing_else(): void
    {
        [, $employee, $order] = $this->soldFifteenKilos();

        $transitions = collect($this->withHeaders($this->headersFor($employee))
            ->getJson("/api/v1/orders/{$order->id}")
            ->assertOk()
            ->json('data.available_transitions'))->pluck('status')->all();

        $this->assertSame([OrderStatus::Delivered->value, OrderStatus::Cancelled->value], $transitions);
    }

    public function test_cash_handed_over_in_full_lands_in_the_branch_box_and_takes_no_more_stock(): void
    {
        // Arrange
        [$branch, $employee, $order, $accounts, $variant] = $this->soldFifteenKilos();

        // Act
        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 150, 'payment_method' => 'cash'],
        ])->assertOk();

        // Assert
        $order->refresh();
        $this->assertSame(OrderStatus::Delivered, $order->status);
        $payment = OrderPayment::query()->where('order_id', $order->id)->sole();
        $this->assertSame((int) $accounts['cash']->id, (int) $payment->treasury_account_id);
        $this->assertSame('5.000', $this->shelf((int) $branch->default_warehouse_id, $variant), 'deducted once, at creation');
        $this->assertSame(1, StockMovement::query()->where('movement_type', MovementType::OrderFulfillment->value)->count());
    }

    public function test_the_handover_is_refused_until_the_whole_amount_is_collected(): void
    {
        [, $employee, $order] = $this->soldFifteenKilos();
        $headers = $this->headersFor($employee);

        // No amount at all: the box is required.
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
        ])->assertUnprocessable()->assertJsonValidationErrors('fields.payment_amount');

        // Part of it.
        $partial = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 100, 'payment_method' => 'cash'],
        ])->assertUnprocessable();

        $this->assertSame(
            'الطلب الفوري يُسلَّم بعد قبض كامل المبلغ — المتبقي 50 د.ل',
            $partial->json('errors')['fields.payment_amount'][0],
        );
        $this->assertSame(OrderStatus::New, $order->refresh()->status);
        $this->assertSame(0, OrderPayment::query()->count(), 'the refused move took its payment back with it');
    }

    public function test_a_transfer_needs_its_receipt_and_lands_in_the_branch_bank_account(): void
    {
        Storage::fake('local');
        [, $employee, $order, $accounts] = $this->soldFifteenKilos();
        $headers = $this->headersFor($employee);

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 150, 'payment_method' => 'bank_transfer'],
        ])->assertUnprocessable()->assertJsonValidationErrors('fields.payment_receipt');

        $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => [
                'payment_amount' => 150,
                'payment_method' => 'bank_transfer',
                'payment_receipt' => UploadedFile::fake()->image('receipt.jpg'),
            ],
        ], ['Accept' => 'application/json'])->assertOk();

        $this->assertSame((int) $accounts['bank']->id, (int) OrderPayment::query()->sole()->treasury_account_id);
    }

    public function test_a_branch_without_a_card_account_refuses_a_card_payment(): void
    {
        [$branch, $employee, $order] = $this->soldFifteenKilos();
        $branch->forceFill(['bank_card_account_id' => null])->save();

        $refused = $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 150, 'payment_method' => 'bank_card'],
        ])->assertUnprocessable();

        $this->assertStringContainsString('لم يُحدَّد حساب البطاقة المصرفية', $refused->json('message'));
        $this->assertSame(OrderStatus::New, $order->refresh()->status);
    }

    public function test_choosing_another_account_needs_its_own_grant(): void
    {
        [, $employee, $order] = $this->soldFifteenKilos();
        $elsewhere = TreasuryAccount::factory()->create();

        $fields = fn (User $user) => collect(collect($this->withHeaders($this->headersFor($user))
            ->getJson("/api/v1/orders/{$order->id}")->json('data.available_transitions'))
            ->firstWhere('status', OrderStatus::Delivered->value)['fields'])->pluck('key')->all();

        $this->assertNotContains('payment_account_id', $fields($employee));

        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 150, 'payment_method' => 'cash', 'payment_account_id' => $elsewhere->id],
        ])->assertUnprocessable();

        $employee->givePermissionTo(PermissionName::ChooseInstantOrderAccount->value);

        $this->assertContains('payment_account_id', $fields($employee));

        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 150, 'payment_method' => 'cash', 'payment_account_id' => $elsewhere->id],
        ])->assertOk();

        $this->assertSame((int) $elsewhere->id, (int) OrderPayment::query()->sole()->treasury_account_id);
    }

    public function test_less_may_be_handed_over_and_the_rest_goes_back_to_the_shelf_but_never_more(): void
    {
        // Arrange
        [$branch, $employee, $order, , $variant] = $this->soldFifteenKilos();
        $line = $order->items()->sole();
        $headers = $this->headersFor($employee);

        // More than ordered.
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ["delivered_{$line->id}" => 16, 'payment_amount' => 160, 'payment_method' => 'cash'],
        ])->assertUnprocessable();

        // Act — the customer takes 10 of 15 and pays for 10.
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ["delivered_{$line->id}" => 10, 'payment_amount' => 100, 'payment_method' => 'cash'],
        ])->assertOk();

        // Assert
        $order->refresh();
        $this->assertSame(OrderStatus::Delivered, $order->status);
        $this->assertSame('100.00', (string) $order->grand_total);
        $this->assertSame('10.000', $this->shelf((int) $branch->default_warehouse_id, $variant), '20 − 10 taken');
    }

    public function test_cancelling_needs_a_reason_and_puts_the_stock_back(): void
    {
        [$branch, $employee, $order, , $variant] = $this->soldFifteenKilos();
        $headers = $this->headersFor($employee);

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
        ])->assertUnprocessable();

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'غيّر رأيه',
        ])->assertOk();

        $this->assertSame(OrderStatus::Cancelled, $order->refresh()->status);
        $this->assertSame('20.000', $this->shelf((int) $branch->default_warehouse_id, $variant));
    }

    public function test_only_the_listed_moves_are_allowed(): void
    {
        [, $employee, $order] = $this->soldFifteenKilos();
        $accountant = User::factory()->create();
        $accountant->givePermissionTo([PermissionName::ViewOrders->value, PermissionName::SettleOrders->value]);

        // جديدة → تم التسوية is not a move.
        $this->withHeaders($this->headersFor($accountant))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
        ])->assertUnprocessable();

        // جديدة → قيد الطباعة is not one either, even for someone holding that grant.
        $printer = User::factory()->create();
        $printer->givePermissionTo([PermissionName::ViewOrders->value, PermissionName::MoveOrderToPrinting->value]);
        $this->withHeaders($this->headersFor($printer))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Printing->value,
        ])->assertForbidden();

        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 150, 'payment_method' => 'cash'],
        ])->assertOk();

        // No ordinary cancel after the customer has the goods.
        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'متأخر',
        ])->assertUnprocessable();

        // A second handover of the same order — a double tap — is refused.
        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
        ])->assertUnprocessable();
        $this->assertSame(1, OrderPayment::query()->count());

        // The branch employee does not settle; the accountant does.
        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
        ])->assertForbidden();

        $this->withHeaders($this->headersFor($accountant))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
        ])->assertOk();

        $this->assertSame(OrderStatus::Settled, $order->refresh()->status);
        $this->assertSame(1, OrderPayment::query()->count(), 'settling books no second sale');
    }

    public function test_an_employee_of_another_branch_reads_the_order_but_cannot_move_it(): void
    {
        [, , $order] = $this->soldFifteenKilos();
        $stranger = $this->branchEmployee($this->counterBranch(name: 'مكتب ولي العهد'));

        $show = $this->withHeaders($this->headersFor($stranger))->getJson("/api/v1/orders/{$order->id}")->assertOk();
        $this->assertSame([], $show->json('data.available_transitions'));

        $this->withHeaders($this->headersFor($stranger))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 150, 'payment_method' => 'cash'],
        ])->assertForbidden();
    }

    public function test_the_normal_edit_refuses_an_instant_order(): void
    {
        [$branch, , $order] = $this->soldFifteenKilos();
        $clerk = User::factory()->create();
        $clerk->givePermissionTo([PermissionName::ViewOrders->value, PermissionName::ManageOrders->value]);

        $this->withHeaders($this->headersFor($clerk))->putJson("/api/v1/orders/{$order->id}", [
            'customer_id' => $order->customer_id,
            'city_id' => $branch->id,
            'items' => [['id' => $order->items()->value('id'), 'product_id' => $order->items()->value('product_id'), 'product_variant_id' => $order->items()->value('product_variant_id'), 'quantity' => 1]],
        ])->assertUnprocessable();
    }
}
