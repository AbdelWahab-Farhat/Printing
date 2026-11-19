<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\CompensationReason;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\Support\GivesPrintableArtwork;
use Tests\TestCase;

/**
 * «أجرة التصميم» — what the customer pays for the design, kept apart from «أجرة المصمم» on the
 * ticket. Hidden from employees, never typed on the new-order form, and set from the order by
 * whoever holds `orders.design_fee` while the order is open. Docs/orders/ORDER-DESIGN-FEE.md.
 *
 * The bags in every order here: 300 at 1.100 = 330.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderDesignFeeTest extends TestCase
{
    use GivesPrintableArtwork;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    // ── helpers ──────────────────────────────────────────────────────────────────────────

    /**
     * @return array{User, array<string, string>}
     */
    private function actor(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    /** @return array<string, string> */
    private function clerk(): array
    {
        return $this->actor(PermissionName::ViewOrders, PermissionName::ManageOrders)[1];
    }

    /** @return array{User, array<string, string>} */
    private function owner(): array
    {
        return $this->actor(PermissionName::ViewOrders, PermissionName::ManageOrders, PermissionName::SetOrderDesignFee);
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        $product = Product::factory()->create(['pricing_mode' => PricingMode::Tiered, 'min_order_quantity' => '100']);
        $variant = ProductVariant::factory()->create(['product_id' => $product->getKey(), 'label' => '25*35']);
        ProductPriceTier::factory()->create(['product_variant_id' => $variant->getKey(), 'min_quantity' => '100', 'unit_price' => '1.100']);
        $customer = Customer::factory()->create();

        $payload = array_merge([
            'customer_id' => $customer->getKey(),
            'city_id' => City::factory()->create(['delivery_price' => '20.00'])->getKey(),
            'address_details' => 'شارع الجمهورية',
            'items' => [[
                'product_id' => $variant->product_id,
                'product_variant_id' => $variant->getKey(),
                'quantity' => '300',
            ]],
        ], $overrides);

        if (! array_key_exists('design_ids', $overrides)
            && ($overrides['design_source'] ?? null) !== DesignSource::InHouse->value) {
            $payload['design_ids'] = [$this->printableDesignId((int) $payload['customer_id'])];
        }

        return $payload;
    }

    /**
     * An order of 330 taken by a clerk.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function order(array $overrides = []): Order
    {
        $id = $this->postJson('/api/v1/orders', $this->payload($overrides), $this->clerk())
            ->assertCreated()
            ->json('data.id');

        return Order::query()->findOrFail($id);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function setFee(Order $order, mixed $fee, array $headers): TestResponse
    {
        return $this->patchJson("/api/v1/orders/{$order->id}/design-fee", ['design_fee' => $fee], $headers);
    }

    // ── setting it ───────────────────────────────────────────────────────────────────────

    public function test_the_holder_sets_the_fee_and_the_customer_pays_it(): void
    {
        // Arrange
        $order = $this->order(['design_source' => DesignSource::InHouse->value]);
        [$owner, $headers] = $this->owner();

        // Act
        $response = $this->setFee($order, '100', $headers);

        // Assert — 330 + 100, decided by a person, and the person is named.
        $response->assertOk()
            ->assertJsonPath('data.design_fee', '100.00')
            ->assertJsonPath('data.grand_total', '430.00')
            ->assertJsonPath('data.design_fee_is_auto', false);
        $order->refresh();
        $this->assertNotNull($order->design_fee_set_at);
        $this->assertSame((int) $owner->id, (int) $order->design_fee_set_by);
    }

    public function test_an_employee_without_the_grant_cannot_set_it(): void
    {
        // Arrange
        $order = $this->order(['design_source' => DesignSource::InHouse->value]);

        // Act
        $response = $this->setFee($order, '100', $this->clerk());

        // Assert
        $response->assertForbidden();
        $this->assertSame('0.00', (string) $order->refresh()->design_fee);
    }

    public function test_a_fee_on_the_customers_artwork_turns_the_design_into_ours(): void
    {
        // Arrange — taken as «تصميم العميل», then redrawn by our designer.
        $order = $this->order(['design_source' => DesignSource::Customer->value]);
        [, $headers] = $this->owner();

        // Act
        $response = $this->setFee($order, '50', $headers);

        // Assert — a fee nobody is charged would be a number with no money behind it.
        $response->assertOk()
            ->assertJsonPath('data.design_source', DesignSource::InHouse->value)
            ->assertJsonPath('data.grand_total', '380.00');
    }

    public function test_clearing_the_fee_leaves_the_design_ours(): void
    {
        // Arrange
        $order = $this->order(['design_source' => DesignSource::Customer->value]);
        [, $headers] = $this->owner();
        $this->setFee($order, '50', $headers)->assertOk();

        // Act
        $response = $this->setFee($order, '0', $headers);

        // Assert — cleared on purpose: still decided, so no ticket fills it in later.
        $response->assertOk()
            ->assertJsonPath('data.design_source', DesignSource::InHouse->value)
            ->assertJsonPath('data.design_fee', '0.00')
            ->assertJsonPath('data.grand_total', '330.00');
        $this->assertNotNull($order->refresh()->design_fee_set_at);
    }

    public function test_the_fee_is_whole_dinars(): void
    {
        // Arrange
        $order = $this->order(['design_source' => DesignSource::InHouse->value]);
        [, $headers] = $this->owner();

        // Act
        $response = $this->setFee($order, '10.25', $headers);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('design_fee', 'errors');
    }

    public function test_the_fee_locks_once_the_order_is_delivered(): void
    {
        // Arrange — the investors' share was worked out from this total at «تم الاستلام».
        $order = Order::factory()->designedInHouse()->status(OrderStatus::Delivered)->create();
        [, $headers] = $this->owner();

        // Act
        $response = $this->setFee($order, '100', $headers);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('design_fee', 'errors');
        $this->assertSame('0.00', (string) $order->refresh()->design_fee);
    }

    public function test_a_compensation_order_takes_no_fee(): void
    {
        // Arrange
        $order = Order::factory()->designedInHouse()->status(OrderStatus::New)->create([
            'is_compensation' => true,
            'compensation_reason' => CompensationReason::cases()[0],
        ]);
        [, $headers] = $this->owner();

        // Act
        $response = $this->setFee($order, '100', $headers);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('design_fee', 'errors');
    }

    // ── who reads it ─────────────────────────────────────────────────────────────────────

    public function test_an_employee_without_the_grant_reads_no_fee_on_the_screen(): void
    {
        // Arrange
        $order = $this->order(['design_source' => DesignSource::InHouse->value]);
        [, $owner] = $this->owner();
        $this->setFee($order, '100', $owner)->assertOk();

        // Act
        $response = $this->getJson("/api/v1/orders/{$order->id}", $this->clerk());

        // Assert — the screens read nothing; the invoice still carries the line the customer pays.
        $response->assertOk()
            ->assertJsonPath('data.design_fee', '0.00')
            ->assertJsonPath('data.invoice_design_fee', '100.00')
            ->assertJsonPath('data.grand_total', '430.00')
            ->assertJsonPath('data.can_set_design_fee', false)
            ->assertJsonMissingPath('data.design_fee_is_auto');
    }

    public function test_the_holder_reads_the_fee_and_may_change_it(): void
    {
        // Arrange
        $order = $this->order(['design_source' => DesignSource::InHouse->value]);
        [, $owner] = $this->owner();
        $this->setFee($order, '100', $owner)->assertOk();

        // Act
        $response = $this->getJson("/api/v1/orders/{$order->id}", $owner);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.design_fee', '100.00')
            ->assertJsonPath('data.can_set_design_fee', true);
    }

    public function test_the_holder_may_not_change_it_on_a_delivered_order(): void
    {
        // Arrange
        $order = Order::factory()->designedInHouse()->status(OrderStatus::Delivered)->create();
        [, $owner] = $this->owner();

        // Act
        $response = $this->getJson("/api/v1/orders/{$order->id}", $owner);

        // Assert
        $response->assertOk()->assertJsonPath('data.can_set_design_fee', false);
    }

    public function test_the_trail_hides_the_fee_from_an_employee_without_the_grant(): void
    {
        // Arrange
        $order = $this->order(['design_source' => DesignSource::InHouse->value]);
        [, $owner] = $this->owner();
        $this->setFee($order, '100', $owner)->assertOk();
        [, $auditor] = $this->actor(PermissionName::ViewOrders, PermissionName::ViewActivityLogs);
        [, $ownerAuditing] = $this->actor(
            PermissionName::ViewOrders,
            PermissionName::ViewActivityLogs,
            PermissionName::SetOrderDesignFee,
        );

        // Act
        $hidden = $this->getJson("/api/v1/orders/{$order->id}/logs", $auditor);
        $shown = $this->getJson("/api/v1/orders/{$order->id}/logs", $ownerAuditing);

        // Assert
        $fees = fn (TestResponse $response): array => collect($response->assertOk()->json('data'))
            ->map(fn (array $entry): mixed => $entry['changes']['attributes']['design_fee'] ?? null)
            ->filter()
            ->values()
            ->all();

        $this->assertSame([], $fees($hidden));
        $this->assertContains('100.00', $fees($shown));
    }

    // ── never on the new-order form, never through an edit ──────────────────────────────

    public function test_a_fee_sent_with_a_new_order_by_an_employee_is_ignored(): void
    {
        // Arrange — an older build still shows the box.
        $payload = $this->payload([
            'design_source' => DesignSource::InHouse->value,
            'design_fee' => '80.00',
        ]);

        // Act
        $response = $this->postJson('/api/v1/orders', $payload, $this->clerk());

        // Assert
        $response->assertCreated()->assertJsonPath('data.grand_total', '330.00');
        $order = Order::query()->sole();
        $this->assertSame('0.00', (string) $order->design_fee);
        $this->assertNull($order->design_fee_set_at);
    }

    public function test_a_fee_sent_with_a_new_order_by_the_holder_is_kept(): void
    {
        // Arrange
        [, $owner] = $this->owner();
        $payload = $this->payload([
            'design_source' => DesignSource::InHouse->value,
            'design_fee' => '80.00',
        ]);

        // Act
        $response = $this->postJson('/api/v1/orders', $payload, $owner);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.design_fee', '80.00')
            ->assertJsonPath('data.grand_total', '410.00');
        $this->assertNotNull(Order::query()->sole()->design_fee_set_at);
    }

    public function test_an_edit_never_moves_the_fee(): void
    {
        // Arrange — the clerk's screen holds 0.00, and every edit sends the whole order back.
        $order = $this->order(['design_source' => DesignSource::InHouse->value]);
        [, $owner] = $this->owner();
        $this->setFee($order, '100', $owner)->assertOk();
        $order->refresh();

        // Act
        $response = $this->putJson("/api/v1/orders/{$order->id}", [
            'city_id' => $order->city_id,
            'design_source' => DesignSource::InHouse->value,
            'design_fee' => '0.00',
            'notes' => 'اتصل قبل التوصيل',
        ], $this->clerk());

        // Assert
        $response->assertOk();
        $this->assertSame('100.00', (string) $order->refresh()->design_fee);
        $this->assertSame('430.00', (string) $order->grand_total);
    }
}
