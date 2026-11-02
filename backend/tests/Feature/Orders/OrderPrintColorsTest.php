<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Audit\AuditValueLabels;
use App\Domain\Audit\Enums\AuditSubject;
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
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «ألوان الطباعة» from the customer's library to the press — PRINT-COLORS.md.
 *
 * The design holds the colors, an order holds **a copy**, the copy follows the design until the
 * order goes to the press and stops there, and the move into «قيد الطباعة» shows it one last time.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderPrintColorsTest extends TestCase
{
    use RefreshDatabase;

    private const RED = ['name' => 'أحمر الشعار', 'code' => 'PANTONE 186 C', 'hex' => '#E4002B'];

    private const BLACK = ['name' => 'أسود النص', 'code' => 'PANTONE Black C', 'hex' => null];

    private const BLUE = ['name' => 'أزرق', 'code' => 'PANTONE 286 C', 'hex' => '#0033A0'];

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Storage::fake('local');
    }

    /**
     * @return array<string, string>
     */
    private function staff(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewOrders->value,
            PermissionName::ManageOrders->value,
            PermissionName::ManageOrderDesigns->value,
            PermissionName::MoveOrderToPrinting->value,
            PermissionName::ViewCustomers->value,
            PermissionName::ManageCustomers->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @param  list<array<string, mixed>>|null  $colors
     */
    private function designWith(Customer $customer, ?array $colors): CustomerDesign
    {
        return CustomerDesign::factory()->for($customer)->create(['print_colors' => $colors]);
    }

    private function order(Customer $customer, OrderStatus $status = OrderStatus::New): Order
    {
        return Order::factory()->forCustomer($customer)->status($status)->create();
    }

    private function attach(array $headers, Order $order, CustomerDesign $design): TestResponse
    {
        return $this->postJson(
            "/api/v1/orders/{$order->id}/designs",
            ['customer_design_id' => $design->id],
            $headers,
        );
    }

    /** The move into «قيد الطباعة» as the order screen offers it. */
    private function printingMove(array $headers, Order $order): ?array
    {
        $transitions = $this->getJson("/api/v1/orders/{$order->id}", $headers)
            ->assertOk()
            ->json('data.available_transitions');

        foreach ($transitions as $transition) {
            if ($transition['status'] === OrderStatus::Printing->value) {
                return $transition;
            }
        }

        return null;
    }

    // ─────────────────────────── the library ───────────────────────────

    public function test_colors_arrive_with_an_upload_and_are_tidied_on_the_way_in(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();

        // Act — multipart, as the app sends it: `print_colors[0][name]`.
        $response = $this->post(
            "/api/v1/customers/{$customer->id}/designs",
            [
                'file' => UploadedFile::fake()->image('logo.png', 400, 400),
                'print_colors' => [
                    ['name' => '  أحمر الشعار ', 'code' => 'PANTONE 186 C', 'hex' => '#e4002b'],
                    ['name' => 'أسود النص', 'code' => '', 'hex' => ''],
                ],
            ],
            $headers + ['Accept' => 'application/json'],
        );

        // Assert — trimmed, the swatch upper-cased, blanks stored as null.
        $response->assertCreated()
            ->assertJsonPath('data.print_colors', [
                ['name' => 'أحمر الشعار', 'code' => 'PANTONE 186 C', 'hex' => '#E4002B'],
                ['name' => 'أسود النص', 'code' => null, 'hex' => null],
            ]);
    }

    public function test_a_design_with_no_colors_says_so_with_an_empty_list(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $this->designWith($customer, null);

        // Act
        $response = $this->getJson("/api/v1/customers/{$customer->id}/designs", $headers);

        // Assert — never null, so the app has one shape to read.
        $response->assertOk()->assertJsonPath('data.0.print_colors', []);
    }

    public function test_a_color_needs_a_name_and_a_swatch_must_be_a_real_hex(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, null);

        // Act
        $response = $this->patchJson(
            "/api/v1/customers/{$customer->id}/designs/{$design->id}",
            ['print_colors' => [['code' => 'PANTONE 186 C'], ['name' => 'أحمر', 'hex' => 'red']]],
            $headers,
        );

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['print_colors.0.name', 'print_colors.1.hex']);
        $this->assertNull($design->fresh()->print_colors);
    }

    public function test_a_design_holds_at_most_twelve_colors(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, null);

        // Act
        $response = $this->patchJson(
            "/api/v1/customers/{$customer->id}/designs/{$design->id}",
            ['print_colors' => array_fill(0, 13, ['name' => 'لون'])],
            $headers,
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors');
    }

    public function test_renaming_a_design_leaves_its_colors_alone(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, [self::RED]);

        // Act — an older app's rename, which knows nothing about colors.
        $response = $this->patchJson(
            "/api/v1/customers/{$customer->id}/designs/{$design->id}",
            ['label' => 'الكيس الكبير'],
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.print_colors', [self::RED]);
    }

    public function test_an_empty_list_clears_the_colors(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, [self::RED]);

        // Act
        $response = $this->patchJson(
            "/api/v1/customers/{$customer->id}/designs/{$design->id}",
            ['print_colors' => []],
            $headers,
        );

        // Assert — one way to say «none»: null in the column, an empty list on the wire.
        $response->assertOk()->assertJsonPath('data.print_colors', []);
        $this->assertNull($design->fresh()->print_colors);
    }

    // ─────────────────────────── the order's copy ───────────────────────────

    public function test_attaching_a_design_copies_its_colors_onto_the_order(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, [self::RED, self::BLACK]);
        $order = $this->order($customer);

        // Act
        $response = $this->attach($headers, $order, $design);

        // Assert
        $response->assertCreated()->assertJsonPath('data.print_colors', [self::RED, self::BLACK]);
        $this->assertSame([self::RED, self::BLACK], OrderDesign::query()->sole()->print_colors);
    }

    public function test_correcting_the_design_reaches_an_order_still_waiting_to_print(): void
    {
        // Arrange — the file attached first, the colors written in afterwards: the common way.
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, null);
        $order = $this->order($customer);
        $this->attach($headers, $order, $design)->assertCreated();

        // Act
        $this->patchJson(
            "/api/v1/customers/{$customer->id}/designs/{$design->id}",
            ['print_colors' => [self::RED]],
            $headers,
        )->assertOk();

        // Assert — the press would otherwise read an empty list off the order.
        $this->assertSame([self::RED], OrderDesign::query()->sole()->print_colors);
    }

    public function test_correcting_the_design_never_rewrites_an_order_already_printed(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, [self::RED]);
        $order = $this->order($customer);
        $this->attach($headers, $order, $design)->assertCreated();
        $order->forceFill(['status' => OrderStatus::Printing])->save();

        // Act
        $this->patchJson(
            "/api/v1/customers/{$customer->id}/designs/{$design->id}",
            ['print_colors' => [self::BLUE]],
            $headers,
        )->assertOk();

        // Assert — that order keeps saying which inks it was printed in.
        $this->assertSame([self::RED], OrderDesign::query()->sole()->print_colors);
    }

    public function test_an_order_changed_on_its_own_keeps_its_own_colors(): void
    {
        // Arrange — this one order is printed in blue, by decision.
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, [self::RED]);
        $order = $this->order($customer);
        $versionId = $this->attach($headers, $order, $design)->json('data.id');
        $this->patchJson(
            "/api/v1/orders/{$order->id}/designs/{$versionId}/colors",
            ['print_colors' => [self::BLUE]],
            $headers,
        )->assertOk();

        // Act — the library is corrected afterwards.
        $this->patchJson(
            "/api/v1/customers/{$customer->id}/designs/{$design->id}",
            ['print_colors' => [self::BLACK]],
            $headers,
        )->assertOk();

        // Assert
        $this->assertSame([self::BLUE], OrderDesign::query()->sole()->print_colors);
    }

    public function test_an_orders_colors_change_without_touching_the_library(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, [self::RED]);
        $order = $this->order($customer);
        $versionId = $this->attach($headers, $order, $design)->json('data.id');

        // Act
        $response = $this->patchJson(
            "/api/v1/orders/{$order->id}/designs/{$versionId}/colors",
            ['print_colors' => [self::BLUE]],
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.print_colors', [self::BLUE]);
        $this->assertSame([self::RED], $design->fresh()->print_colors);
    }

    public function test_an_orders_colors_lock_once_it_is_at_the_press(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $design = $this->designWith($customer, [self::RED]);
        $order = $this->order($customer);
        $versionId = $this->attach($headers, $order, $design)->json('data.id');
        $order->forceFill(['status' => OrderStatus::Printing])->save();

        // Act
        $response = $this->patchJson(
            "/api/v1/orders/{$order->id}/designs/{$versionId}/colors",
            ['print_colors' => [self::BLUE]],
            $headers,
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors');
        $this->assertSame([self::RED], OrderDesign::query()->sole()->print_colors);
    }

    public function test_another_orders_version_is_not_reachable_through_this_one(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $order = $this->order($customer);
        $stranger = OrderDesign::factory()->create();

        // Act
        $response = $this->patchJson(
            "/api/v1/orders/{$order->id}/designs/{$stranger->id}/colors",
            ['print_colors' => [self::BLUE]],
            $headers,
        );

        // Assert
        $response->assertNotFound();
    }

    // ─────────────────────────── the reminder on the way to the press ───────────────────────────

    public function test_the_move_to_the_press_shows_the_approved_versions_colors(): void
    {
        // Arrange — version 1 approved in red, version 2 still proposed in blue.
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $order = $this->order($customer, OrderStatus::ReadyToPrint);
        OrderDesign::factory()->approved()->create([
            'order_id' => $order->id,
            'version' => 1,
            'print_colors' => [self::RED, self::BLACK],
        ]);
        OrderDesign::factory()->create([
            'order_id' => $order->id,
            'version' => 2,
            'print_colors' => [self::BLUE],
        ]);

        // Act
        $printing = $this->printingMove($headers, $order);

        // Assert — the approved file is the one going on the press, whatever came after it.
        $this->assertNotNull($printing);
        $reminder = collect($printing['fields'])->firstWhere('type', 'print_colors');
        $this->assertNotNull($reminder);
        $this->assertSame('ألوان الطباعة — النسخة 1 المعتمدة', $reminder['label']);
        $this->assertSame([self::RED, self::BLACK], $reminder['colors']);
        $this->assertFalse($reminder['required']);
    }

    public function test_with_nothing_approved_the_newest_version_not_turned_down_is_shown(): void
    {
        // Arrange — the short road: a file attached and never formally approved.
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $order = $this->order($customer, OrderStatus::ReadyToPrint);
        OrderDesign::factory()->create(['order_id' => $order->id, 'version' => 1, 'print_colors' => [self::RED]]);
        OrderDesign::factory()->rejected()->create([
            'order_id' => $order->id,
            'version' => 2,
            'print_colors' => [self::BLUE],
        ]);

        // Act
        $printing = $this->printingMove($headers, $order);

        // Assert
        $reminder = collect($printing['fields'])->firstWhere('type', 'print_colors');
        $this->assertSame('ألوان الطباعة — النسخة 1', $reminder['label']);
        $this->assertSame([self::RED], $reminder['colors']);
    }

    public function test_an_order_with_no_colors_on_record_gets_no_reminder(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $order = $this->order($customer, OrderStatus::ReadyToPrint);
        OrderDesign::factory()->approved()->create(['order_id' => $order->id, 'print_colors' => null]);

        // Act
        $printing = $this->printingMove($headers, $order);

        // Assert — no empty box; and no `colors` key leaks onto the fields that remain.
        $this->assertNull(collect($printing['fields'])->firstWhere('type', 'print_colors'));
        foreach ($printing['fields'] as $field) {
            $this->assertArrayNotHasKey('colors', $field);
        }
    }

    public function test_the_reminder_is_read_not_answered(): void
    {
        // Arrange
        $headers = $this->staff();
        $customer = Customer::factory()->create();
        $order = $this->order($customer, OrderStatus::ReadyToPrint);
        OrderDesign::factory()->approved()->create(['order_id' => $order->id, 'print_colors' => [self::RED]]);

        // Act — the move goes through exactly as it did before the reminder existed.
        $response = $this->postJson(
            "/api/v1/orders/{$order->id}/status",
            ['status' => OrderStatus::Printing->value],
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.status', OrderStatus::Printing->value);
    }

    // ─────────────────────────── the history ───────────────────────────

    public function test_the_history_reads_the_colors_as_words_not_json(): void
    {
        // Arrange — nothing; the cast on the model is what the translation is found through.

        // Act
        $labels = AuditValueLabels::forChanges(
            AuditSubject::CustomerDesign,
            ['print_colors' => null],
            ['print_colors' => [self::RED, ['name' => 'أبيض', 'code' => null, 'hex' => null]]],
        );

        // Assert
        $this->assertSame(
            'أحمر الشعار (PANTONE 186 C)، أبيض',
            $labels['attributes']['print_colors'],
        );
        $this->assertArrayNotHasKey('print_colors', $labels['old']);
    }
}
