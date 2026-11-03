<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «ألوان الطباعة» from the customer's own app — PRINT-COLORS.md §8.
 *
 * The customer chooses each ink's name and swatch; our team writes the code. Once one code is
 * written the list is locked for the customer.
 *
 * Arrange - Act - Assert throughout.
 */
class ClientDesignColorsTest extends TestCase
{
    use RefreshDatabase;

    private const RED = ['name' => 'أحمر الشعار', 'code' => null, 'hex' => '#E4002B'];

    private const BLUE = ['name' => 'أزرق', 'code' => null, 'hex' => '#0033A0'];

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('local');
    }

    private function customer(string $phone = '0911111111'): Customer
    {
        return Customer::factory()->registered()->create(['phone' => $phone]);
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return [
            'Authorization' => 'Bearer '.$customer->createToken('test-device')->plainTextToken,
            'Accept' => 'application/json',
        ];
    }

    /**
     * @param  list<array<string, mixed>>|null  $colors
     */
    private function designOf(Customer $customer, ?array $colors = null): CustomerDesign
    {
        return CustomerDesign::factory()->create([
            'customer_id' => $customer->id,
            'print_colors' => $colors,
        ]);
    }

    public function test_a_customer_uploads_a_design_with_the_colours_they_chose(): void
    {
        // Arrange
        $me = $this->customer();

        // Act — multipart, with a code slipped in that must not survive.
        $response = $this->post('/api/v1/client/designs', [
            'file' => UploadedFile::fake()->image('logo.png', 300, 300),
            'print_colors' => [
                ['name' => 'أحمر الشعار', 'hex' => '#e4002b', 'code' => 'PANTONE 186 C'],
            ],
        ], $this->bearerFor($me));

        // Assert — the name and the swatch are theirs; the code is ours to write.
        $response->assertCreated()
            ->assertJsonPath('data.print_colors', [self::RED])
            ->assertJsonPath('data.print_colors_locked', false);
        $this->assertSame([self::RED], CustomerDesign::query()->sole()->print_colors);
    }

    public function test_a_customer_colour_needs_a_swatch(): void
    {
        // Arrange
        $me = $this->customer();
        $design = $this->designOf($me);

        // Act
        $response = $this->putJson(
            "/api/v1/client/designs/{$design->id}/colors",
            ['print_colors' => [['name' => 'أحمر']]],
            $this->bearerFor($me),
        );

        // Assert — choosing the colour is the point of letting them.
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors.0.hex');
    }

    public function test_a_customer_changes_their_colours_and_the_open_order_follows(): void
    {
        // Arrange — the design is already on an order nobody has started printing.
        $me = $this->customer();
        $design = $this->designOf($me, [self::RED]);
        $order = Order::factory()->forCustomer($me)->status(OrderStatus::Requested)->create();
        $version = OrderDesign::factory()->create([
            'order_id' => $order->id,
            'customer_design_id' => $design->id,
            'print_colors' => [self::RED],
        ]);

        // Act
        $response = $this->putJson(
            "/api/v1/client/designs/{$design->id}/colors",
            ['print_colors' => [self::BLUE]],
            $this->bearerFor($me),
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.print_colors', [self::BLUE]);
        $this->assertSame([self::BLUE], $version->fresh()->print_colors);
    }

    public function test_once_our_team_writes_a_code_the_customer_can_no_longer_change_them(): void
    {
        // Arrange
        $me = $this->customer();
        $confirmed = [['name' => 'أحمر الشعار', 'code' => 'PANTONE 186 C', 'hex' => '#E4002B']];
        $design = $this->designOf($me, $confirmed);

        // Act
        $response = $this->putJson(
            "/api/v1/client/designs/{$design->id}/colors",
            ['print_colors' => [self::BLUE]],
            $this->bearerFor($me),
        );

        // Assert — refused, and the codes our team wrote are still there.
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors');
        $this->assertSame($confirmed, $design->fresh()->print_colors);
    }

    public function test_the_customer_sees_the_code_our_team_wrote_and_that_the_list_is_locked(): void
    {
        // Arrange
        $me = $this->customer();
        $this->designOf($me, [['name' => 'أحمر الشعار', 'code' => 'PANTONE 186 C', 'hex' => '#E4002B']]);

        // Act
        $response = $this->getJson('/api/v1/client/designs', $this->bearerFor($me));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.print_colors.0.code', 'PANTONE 186 C')
            ->assertJsonPath('data.0.print_colors_locked', true);
    }

    public function test_another_customers_design_is_not_reachable(): void
    {
        // Arrange
        $me = $this->customer();
        $theirs = $this->designOf($this->customer('0922222222'));

        // Act
        $response = $this->putJson(
            "/api/v1/client/designs/{$theirs->id}/colors",
            ['print_colors' => [self::RED]],
            $this->bearerFor($me),
        );

        // Assert
        $response->assertNotFound();
        $this->assertNull($theirs->fresh()->print_colors);
    }

    public function test_the_press_is_warned_when_a_colour_still_has_no_code(): void
    {
        // Arrange — the customer's colour reached the order with no code on it.
        $user = User::factory()->create();
        foreach ([PermissionName::ViewOrders, PermissionName::MoveOrderToPrinting] as $permission) {
            Permission::findOrCreate($permission->value, 'web');
            $user->givePermissionTo($permission->value);
        }
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create();
        OrderDesign::factory()->approved()->create(['order_id' => $order->id, 'print_colors' => [self::RED]]);

        // Act
        $transitions = $this->getJson(
            "/api/v1/orders/{$order->id}",
            ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken],
        )->assertOk()->json('data.available_transitions');

        // Assert
        $printing = collect($transitions)->firstWhere('status', OrderStatus::Printing->value);
        $reminder = collect($printing['fields'])->firstWhere('type', 'print_colors');
        $this->assertStringContainsString('لون بلا رمز', $reminder['hint']);
    }
}
