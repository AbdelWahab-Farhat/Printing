<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Delivery\Models\ShippingCompany;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The companies that carry our parcels.
 *
 * **A record rather than a typed-in name, and that is the whole point of this file.** The column
 * used to be free text, so «درب» and «شركة درب» and «درب للشحن» were three companies as far as
 * any report was concerned. A row has one name, can be switched off when we stop dealing with
 * it, and keeps a history of who changed what.
 *
 * Arrange - Act - Assert throughout.
 */
class ShippingCompanyTest extends TestCase
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
     * @return array<string, string>
     */
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @return array<string, string>
     */
    private function viewer(): array
    {
        return $this->auth(PermissionName::ViewShippingCompanies);
    }

    /**
     * @return array<string, string>
     */
    private function manager(): array
    {
        return $this->auth(PermissionName::ViewShippingCompanies, PermissionName::ManageShippingCompanies);
    }

    /**
     * @return array<string, string>
     */
    private function outsider(): array
    {
        return $this->auth(PermissionName::ViewOrders);
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'درب',
            'phone' => '0912345678',
            'notes' => 'الفرع الرئيسي زناتة',
        ], $overrides);
    }

    // ─────────────────────────────── listing ───────────────────────────────

    public function test_a_viewer_can_list_the_companies(): void
    {
        // Arrange
        ShippingCompany::factory()->count(2)->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/shipping-companies');

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure([
                'data' => [['id', 'name', 'phone', 'notes', 'is_active', 'created_at']],
                'meta' => ['current_page', 'per_page', 'last_page', 'total'],
            ]);
    }

    public function test_listing_them_needs_a_permission(): void
    {
        // Arrange
        $headers = $this->outsider();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/shipping-companies');

        // Assert
        $response->assertStatus(403)->assertJsonPath('status', false);
    }

    public function test_the_list_can_be_narrowed_to_the_ones_still_in_use(): void
    {
        // Arrange
        ShippingCompany::factory()->create(['name' => 'شركة عاملة']);
        ShippingCompany::factory()->inactive()->create(['name' => 'شركة توقفنا معها']);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/shipping-companies?is_active=1');

        // Assert — the picker on a dispatch screen asks this question every time it opens.
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'شركة عاملة');
    }

    public function test_a_company_can_be_found_by_name(): void
    {
        // Arrange
        ShippingCompany::factory()->create(['name' => 'درب للشحن السريع']);
        ShippingCompany::factory()->create(['name' => 'الفتح']);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/shipping-companies?search=درب');

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'درب للشحن السريع');
    }

    // ─────────────────────────────── creating ───────────────────────────────

    public function test_a_manager_can_add_a_company(): void
    {
        // Arrange
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/shipping-companies', $this->payload());

        // Assert
        $response->assertCreated()
            ->assertJsonPath('message', 'تم إضافة شركة التوصيل بنجاح')
            ->assertJsonPath('data.name', 'درب')
            ->assertJsonPath('data.is_active', true);

        $this->assertDatabaseHas('shipping_companies', ['name' => 'درب', 'is_active' => true]);
    }

    public function test_a_new_company_is_in_use_from_the_moment_it_is_added(): void
    {
        // Arrange — nobody adds a company they are not about to use.
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/shipping-companies', ['name' => 'شركة بلا تفاصيل']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.is_active', true);
    }

    public function test_adding_one_needs_more_than_being_able_to_read_them(): void
    {
        // Arrange
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/shipping-companies', $this->payload());

        // Assert
        $response->assertStatus(403);
        $this->assertDatabaseMissing('shipping_companies', ['name' => 'درب']);
    }

    public function test_two_companies_cannot_share_a_name(): void
    {
        // Arrange — one name, one company: the entire reason this stopped being free text.
        ShippingCompany::factory()->create(['name' => 'درب']);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/shipping-companies', $this->payload());

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('name');
    }

    public function test_a_removed_company_gives_its_name_back(): void
    {
        // Arrange
        $removed = ShippingCompany::factory()->create(['name' => 'درب']);
        $removed->delete();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/shipping-companies', $this->payload());

        // Assert — the unique index ignores soft-deleted rows, and so must the rule that
        // mirrors it, or validation refuses what the database would have accepted.
        $response->assertCreated();
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    #[DataProvider('invalidPayloads')]
    public function test_a_company_is_refused_when_its_details_do_not_make_sense(
        array $overrides,
        string $invalidField,
    ): void {
        // Arrange
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/shipping-companies', $this->payload($overrides));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors($invalidField);
    }

    /**
     * @return array<string, array{0: array<string, mixed>, 1: string}>
     */
    public static function invalidPayloads(): array
    {
        return [
            'no name' => [['name' => null], 'name'],
            'a name of one letter' => [['name' => 'د'], 'name'],
            'a phone that is a sentence' => [['phone' => str_repeat('٩', 40)], 'phone'],
        ];
    }

    // ─────────────────────────────── editing ───────────────────────────────

    public function test_a_manager_can_correct_a_company(): void
    {
        // Arrange
        $company = ShippingCompany::factory()->create(['name' => 'درب', 'phone' => '0910000000']);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/shipping-companies/{$company->id}",
            $this->payload(['name' => 'درب للشحن', 'phone' => '0911111111']),
        );

        // Assert
        $response->assertOk()->assertJsonPath('message', 'تم تحديث شركة التوصيل بنجاح');
        $this->assertDatabaseHas('shipping_companies', [
            'id' => $company->id,
            'name' => 'درب للشحن',
            'phone' => '0911111111',
        ]);
    }

    public function test_a_company_may_keep_its_own_name(): void
    {
        // Arrange
        $company = ShippingCompany::factory()->create(['name' => 'درب']);
        $headers = $this->manager();

        // Act — editing the phone and leaving the name alone must not trip the unique rule.
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/shipping-companies/{$company->id}",
            $this->payload(['name' => 'درب', 'phone' => '0915555555']),
        );

        // Assert
        $response->assertOk();
    }

    public function test_a_company_cannot_take_another_ones_name(): void
    {
        // Arrange
        ShippingCompany::factory()->create(['name' => 'درب']);
        $other = ShippingCompany::factory()->create(['name' => 'الفتح']);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/shipping-companies/{$other->id}",
            $this->payload(['name' => 'درب']),
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('name');
        $this->assertDatabaseHas('shipping_companies', ['id' => $other->id, 'name' => 'الفتح']);
    }

    public function test_a_company_we_stopped_dealing_with_is_switched_off_rather_than_removed(): void
    {
        // Arrange
        $company = ShippingCompany::factory()->create();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/shipping-companies/{$company->id}",
            $this->payload(['name' => $company->name, 'is_active' => false]),
        );

        // Assert — old orders still name it; it simply stops being offered on new ones.
        $response->assertOk()->assertJsonPath('data.is_active', false);
    }

    // ─────────────────────────────── removing ───────────────────────────────

    public function test_a_manager_can_remove_a_company(): void
    {
        // Arrange
        $company = ShippingCompany::factory()->create();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->deleteJson("/api/v1/shipping-companies/{$company->id}");

        // Assert
        $response->assertOk()->assertJsonPath('message', 'تم حذف شركة التوصيل بنجاح');
        $this->assertSoftDeleted('shipping_companies', ['id' => $company->id]);
    }

    public function test_removing_a_company_leaves_the_orders_it_carried_alone(): void
    {
        // Arrange
        $company = ShippingCompany::factory()->create(['name' => 'درب']);
        $order = Order::factory()->status(OrderStatus::OutForDelivery)->create([
            'shipping_company_id' => $company->id,
            'shipping_company' => 'درب',
        ]);
        $headers = $this->manager();

        // Act
        $this->withHeaders($headers)->deleteJson("/api/v1/shipping-companies/{$company->id}");

        // Assert — the name on the order is a snapshot, like the city's. What an order said
        // carried it is history, and history does not change because a list did.
        $this->assertSame('درب', $order->fresh()->shipping_company);
    }

    public function test_removing_one_needs_the_permission(): void
    {
        // Arrange
        $company = ShippingCompany::factory()->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->deleteJson("/api/v1/shipping-companies/{$company->id}");

        // Assert
        $response->assertStatus(403);
        $this->assertDatabaseHas('shipping_companies', ['id' => $company->id, 'deleted_at' => null]);
    }

    public function test_a_company_that_does_not_exist_is_a_404(): void
    {
        // Arrange
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/shipping-companies/9999');

        // Assert
        $response->assertNotFound();
    }
}
