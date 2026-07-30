<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerShop;
use App\Domain\Identity\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Every test follows Arrange - Act - Assert: state is prepared first, exactly one call is
 * made, and only then is anything asserted.
 */
class CustomerTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, string>
     */
    private function auth(): array
    {
        $user = User::factory()->create();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * Empties the table and rewinds the id sequence, so a test can assert on the very first
     * code (C1) rather than on whatever number the sequence happens to be at.
     */
    private function resetCustomerSequence(): void
    {
        DB::statement('TRUNCATE customers RESTART IDENTITY CASCADE');
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'مخبز النخيل',
            'primary_phone' => '0912345678',
        ], $overrides);
    }

    // ─────────────────────────── customer code ───────────────────────────

    public function test_the_first_customer_gets_the_code_c1(): void
    {
        // Arrange
        $this->resetCustomerSequence();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $this->payload());

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.code', 'C1')
            ->assertJsonPath('data.id', 1);
    }

    public function test_codes_increment_c1_c2_c3_in_order(): void
    {
        // Arrange
        $this->resetCustomerSequence();
        $headers = $this->auth();

        // Act — each needs its own phone number, since one number belongs to one customer.
        $codes = [];
        foreach (['أول', 'ثاني', 'ثالث'] as $index => $name) {
            $codes[] = $this->withHeaders($headers)
                ->postJson('/api/v1/customers', $this->payload([
                    'name' => $name,
                    'primary_phone' => '09120000'.(10 + $index),
                ]))
                ->assertCreated()
                ->json('data.code');
        }

        // Assert
        $this->assertSame(['C1', 'C2', 'C3'], $codes);
    }

    public function test_the_code_always_matches_the_id(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $this->payload());

        // Assert
        $response->assertCreated();
        $this->assertSame('C'.$response->json('data.id'), $response->json('data.code'));
    }

    public function test_a_client_cannot_choose_its_own_code_or_id(): void
    {
        // Arrange
        $headers = $this->auth();
        $payload = $this->payload(['code' => 'C999', 'id' => 999]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $payload);

        // Assert
        $response->assertCreated();
        $this->assertNotSame('C999', $response->json('data.code'));
        $this->assertNotSame(999, $response->json('data.id'));
        $this->assertDatabaseMissing('customers', ['code' => 'C999']);
    }

    public function test_the_code_does_not_change_when_the_customer_is_updated(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $originalCode = $customer->code;
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/customers/{$customer->id}", $this->payload(['name' => 'اسم جديد']));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.code', $originalCode)
            ->assertJsonPath('data.name', 'اسم جديد');
    }

    // ─────────────────────────── create ───────────────────────────

    public function test_create_stores_the_customer_and_defaults_to_active(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $this->payload());

        // Assert
        $response->assertCreated()
            ->assertJson([
                'status' => true,
                'message' => 'تم إضافة العميل بنجاح',
                'data' => [
                    'name' => 'مخبز النخيل',
                    'primary_phone' => '0912345678',
                    'is_active' => true,
                    'shops' => [],
                ],
            ])
            ->assertJsonStructure([
                'status',
                'message',
                'data' => ['id', 'code', 'name', 'primary_phone', 'is_active', 'shops', 'created_at', 'updated_at'],
            ]);

        $this->assertDatabaseHas('customers', ['name' => 'مخبز النخيل', 'is_active' => true]);
    }

    public function test_create_accepts_shops_inline(): void
    {
        // Arrange
        $headers = $this->auth();
        $payload = $this->payload([
            'shops' => [
                ['name' => 'فرع طرابلس', 'location' => 'شارع الجمهورية', 'page_url' => 'https://facebook.com/branch1'],
                ['name' => 'فرع بنغازي', 'location' => 'شارع دبي'],
            ],
        ]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $payload);

        // Assert
        $response->assertCreated()
            ->assertJsonCount(2, 'data.shops')
            ->assertJsonPath('data.shops.0.name', 'فرع طرابلس')
            ->assertJsonPath('data.shops.0.page_url', 'https://facebook.com/branch1')
            // A shop without a page link stores null rather than an empty string.
            ->assertJsonPath('data.shops.1.page_url', null);

        $this->assertDatabaseCount('customer_shops', 2);
        $this->assertDatabaseHas('customer_shops', [
            'customer_id' => $response->json('data.id'),
            'name' => 'فرع بنغازي',
            'location' => 'شارع دبي',
            'page_url' => null,
        ]);
    }

    public function test_create_can_set_the_customer_inactive(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/customers', $this->payload(['is_active' => false]));

        // Assert
        $response->assertCreated()->assertJsonPath('data.is_active', false);
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    #[DataProvider('invalidCustomerCases')]
    public function test_create_rejects_invalid_input(array $overrides, string $invalidField): void
    {
        // Arrange
        $headers = $this->auth();
        $payload = $this->payload($overrides);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/customers', $payload);

        // Assert
        $response->assertStatus(422)
            ->assertJson(['status' => false, 'data' => null])
            ->assertJsonValidationErrors($invalidField);
    }

    /**
     * @return array<string, array{array<string, mixed>, string}>
     */
    public static function invalidCustomerCases(): array
    {
        return [
            'name missing' => [['name' => ''], 'name'],
            'name too short' => [['name' => 'م'], 'name'],
            'phone missing' => [['primary_phone' => ''], 'primary_phone'],
            'phone too short' => [['primary_phone' => '12345'], 'primary_phone'],
            'phone with letters' => [['primary_phone' => '09abcdefgh'], 'primary_phone'],
            'phone with symbols' => [['primary_phone' => '091-234-5678'], 'primary_phone'],
            'is_active not boolean' => [['is_active' => 'maybe'], 'is_active'],
            'shops not a list' => [['shops' => 'nope'], 'shops'],
            'shop without a name' => [['shops' => [['location' => 'x']]], 'shops.0.name'],
            'shop without a location' => [['shops' => [['name' => 'x']]], 'shops.0.location'],
            'shop with a bad url' => [['shops' => [['name' => 'x', 'location' => 'y', 'page_url' => 'not-a-url']]], 'shops.0.page_url'],
        ];
    }

    // ─────────────────── one phone belongs to one customer ───────────────────

    public function test_create_rejects_a_phone_already_used_by_another_customer(): void
    {
        // Arrange
        Customer::factory()->create(['primary_phone' => '0915550009']);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/customers', $this->payload(['primary_phone' => '0915550009']));

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors('primary_phone')
            ->assertJsonPath('errors.primary_phone.0', 'رقم الهاتف مستخدم مسبقاً لعميل آخر');

        $this->assertDatabaseCount('customers', 1);
    }

    public function test_update_allows_a_customer_to_keep_its_own_phone(): void
    {
        // Arrange
        $customer = Customer::factory()->create(['primary_phone' => '0915551111']);
        $headers = $this->auth();

        // Act — saving the form untouched must not collide with itself.
        $response = $this->withHeaders($headers)->putJson("/api/v1/customers/{$customer->id}", [
            'name' => 'اسم محدث',
            'primary_phone' => '0915551111',
        ]);

        // Assert
        $response->assertOk()->assertJsonPath('data.primary_phone', '0915551111');
    }

    public function test_update_rejects_a_phone_taken_by_a_different_customer(): void
    {
        // Arrange
        $customer = Customer::factory()->create(['primary_phone' => '0915552222']);
        Customer::factory()->create(['primary_phone' => '0915553333']);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->putJson("/api/v1/customers/{$customer->id}", [
            'name' => 'اسم',
            'primary_phone' => '0915553333',
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('primary_phone');
        $this->assertDatabaseHas('customers', ['id' => $customer->id, 'primary_phone' => '0915552222']);
    }

    public function test_the_database_itself_refuses_a_duplicate_phone(): void
    {
        // Arrange — validation can be bypassed by a seeder or a race; the index cannot.
        Customer::factory()->create(['primary_phone' => '0915554444']);

        // Assert
        $this->expectException(QueryException::class);

        // Act
        Customer::factory()->create(['primary_phone' => '0915554444']);
    }

    public function test_create_requires_authentication(): void
    {
        // Act
        $response = $this->postJson('/api/v1/customers', $this->payload());

        // Assert
        $response->assertStatus(401)->assertJson(['status' => false, 'data' => null]);
    }

    // ─────────────────────────── list ───────────────────────────

    public function test_index_returns_a_paginated_envelope_newest_first(): void
    {
        // Arrange
        Customer::factory()->count(3)->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/customers');

        // Assert
        $response->assertOk()
            ->assertJsonStructure([
                'status',
                'message',
                'data' => [['id', 'code', 'name', 'primary_phone', 'is_active', 'shops']],
                'meta' => ['current_page', 'per_page', 'last_page', 'total'],
            ]);

        $ids = array_column($response->json('data'), 'id');
        $sorted = $ids;
        rsort($sorted);
        $this->assertSame($sorted, $ids, 'Customers should be listed newest first.');
    }

    public function test_index_handles_an_empty_result_set(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/customers');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data', [])
            ->assertJsonPath('meta.total', 0);
    }

    public function test_index_paginates(): void
    {
        // Arrange
        Customer::factory()->count(5)->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/customers?per_page=2');

        // Assert
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.per_page', 2)
            ->assertJsonPath('meta.total', 5)
            ->assertJsonPath('meta.last_page', 3);
    }

    public function test_index_caps_an_absurd_page_size(): void
    {
        // Arrange
        Customer::factory()->count(3)->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/customers?per_page=100000');

        // Assert
        $response->assertOk()->assertJsonPath('meta.per_page', 100);
    }

    public function test_index_searches_by_name_code_and_phone(): void
    {
        // Arrange
        $target = Customer::factory()->create(['name' => 'مطبعة الأمل', 'primary_phone' => '0915550001']);
        Customer::factory()->create(['name' => 'شركة أخرى', 'primary_phone' => '0918880002']);
        $headers = $this->auth();

        foreach (['مطبعة', $target->code, '5550001'] as $term) {
            // Act
            $response = $this->withHeaders($headers)
                ->getJson('/api/v1/customers?search='.urlencode((string) $term));

            // Assert
            $response->assertOk();
            $this->assertSame(
                [$target->id],
                array_column($response->json('data'), 'id'),
                "Search term [{$term}] should match only the target customer.",
            );
        }
    }

    public function test_index_search_is_case_insensitive(): void
    {
        // Arrange
        $target = Customer::factory()->create(['name' => 'Alpha Printing']);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/customers?search=alpha');

        // Assert
        $response->assertOk();
        $this->assertSame([$target->id], array_column($response->json('data'), 'id'));
    }

    public function test_index_filters_by_activity(): void
    {
        // Arrange
        $active = Customer::factory()->create();
        $inactive = Customer::factory()->inactive()->create();
        $headers = $this->auth();

        // Act
        $activeOnly = $this->withHeaders($headers)->getJson('/api/v1/customers?is_active=1');
        $inactiveOnly = $this->withHeaders($headers)->getJson('/api/v1/customers?is_active=0');

        // Assert
        $this->assertSame([$active->id], array_column($activeOnly->json('data'), 'id'));
        $this->assertSame([$inactive->id], array_column($inactiveOnly->json('data'), 'id'));
    }

    public function test_index_requires_authentication(): void
    {
        // Act
        $response = $this->getJson('/api/v1/customers');

        // Assert
        $response->assertStatus(401);
    }

    // ─────────────────────────── show ───────────────────────────

    public function test_show_returns_the_customer_with_its_shops(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        CustomerShop::factory()->count(2)->create(['customer_id' => $customer->id]);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/customers/{$customer->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.id', $customer->id)
            ->assertJsonPath('data.code', $customer->code)
            ->assertJsonCount(2, 'data.shops');
    }

    public function test_show_returns_404_for_an_unknown_customer(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/customers/999999');

        // Assert
        $response->assertNotFound()
            ->assertJson([
                'status' => false,
                'message' => 'العنصر المطلوب غير موجود',
                'data' => null,
            ]);
    }

    public function test_show_requires_authentication(): void
    {
        // Arrange
        $customer = Customer::factory()->create();

        // Act
        $response = $this->getJson("/api/v1/customers/{$customer->id}");

        // Assert
        $response->assertStatus(401);
    }

    // ─────────────────────────── update ───────────────────────────

    public function test_update_changes_the_basic_fields(): void
    {
        // Arrange
        $customer = Customer::factory()->create(['name' => 'قديم', 'primary_phone' => '0911111111']);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->putJson("/api/v1/customers/{$customer->id}", [
            'name' => 'جديد',
            'primary_phone' => '0922222222',
        ]);

        // Assert
        $response->assertOk()
            ->assertJson([
                'status' => true,
                'message' => 'تم تحديث بيانات العميل بنجاح',
                'data' => ['name' => 'جديد', 'primary_phone' => '0922222222'],
            ]);

        $this->assertDatabaseHas('customers', ['id' => $customer->id, 'name' => 'جديد']);
    }

    public function test_update_without_is_active_does_not_reactivate_a_deactivated_customer(): void
    {
        // Arrange
        $customer = Customer::factory()->inactive()->create();
        $headers = $this->auth();

        // Act — payload deliberately omits is_active.
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/customers/{$customer->id}", $this->payload());

        // Assert
        $response->assertOk()->assertJsonPath('data.is_active', false);
        $this->assertDatabaseHas('customers', ['id' => $customer->id, 'is_active' => false]);
    }

    public function test_update_leaves_shops_alone_when_the_key_is_absent(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        CustomerShop::factory()->count(2)->create(['customer_id' => $customer->id]);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/customers/{$customer->id}", $this->payload());

        // Assert
        $response->assertOk()->assertJsonCount(2, 'data.shops');
        $this->assertDatabaseCount('customer_shops', 2);
    }

    public function test_update_with_an_empty_shops_array_removes_every_shop(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        CustomerShop::factory()->count(2)->create(['customer_id' => $customer->id]);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/customers/{$customer->id}", $this->payload(['shops' => []]));

        // Assert
        $response->assertOk()->assertJsonCount(0, 'data.shops');
        $this->assertDatabaseCount('customer_shops', 0);
    }

    public function test_update_syncs_shops_updating_adding_and_removing_in_one_call(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $kept = CustomerShop::factory()->create(['customer_id' => $customer->id, 'name' => 'الأصلي']);
        $removed = CustomerShop::factory()->create(['customer_id' => $customer->id]);
        $headers = $this->auth();
        $payload = $this->payload([
            'shops' => [
                ['id' => $kept->id, 'name' => 'الأصلي المعدل', 'location' => 'موقع جديد'],
                ['name' => 'محل مضاف', 'location' => 'موقع ثالث'],
            ],
        ]);

        // Act
        $response = $this->withHeaders($headers)->putJson("/api/v1/customers/{$customer->id}", $payload);

        // Assert
        $response->assertOk()->assertJsonCount(2, 'data.shops');

        // The kept shop was edited in place, so its id survived.
        $this->assertDatabaseHas('customer_shops', [
            'id' => $kept->id,
            'name' => 'الأصلي المعدل',
            'location' => 'موقع جديد',
        ]);
        $this->assertDatabaseMissing('customer_shops', ['id' => $removed->id]);
        $this->assertDatabaseHas('customer_shops', ['customer_id' => $customer->id, 'name' => 'محل مضاف']);
        $this->assertDatabaseCount('customer_shops', 2);
    }

    public function test_update_rejects_a_shop_id_belonging_to_another_customer(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $otherShop = CustomerShop::factory()->create();
        $headers = $this->auth();
        $payload = $this->payload([
            'shops' => [['id' => $otherShop->id, 'name' => 'اختراق', 'location' => 'مكان']],
        ]);

        // Act
        $response = $this->withHeaders($headers)->putJson("/api/v1/customers/{$customer->id}", $payload);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('shops.0.id');
        $this->assertDatabaseHas('customer_shops', ['id' => $otherShop->id, 'name' => $otherShop->name]);
    }

    public function test_update_validates_its_input(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/customers/{$customer->id}", ['name' => '', 'primary_phone' => 'abc']);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['name', 'primary_phone']);
    }

    public function test_update_returns_404_for_an_unknown_customer(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/customers/999999', $this->payload());

        // Assert
        $response->assertNotFound();
    }

    public function test_update_requires_authentication(): void
    {
        // Arrange
        $customer = Customer::factory()->create();

        // Act
        $response = $this->putJson("/api/v1/customers/{$customer->id}", $this->payload());

        // Assert
        $response->assertStatus(401);
    }

    // ─────────────────────────── activation ───────────────────────────

    public function test_activation_can_deactivate_a_customer(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/customers/{$customer->id}/activation", ['is_active' => false]);

        // Assert
        $response->assertOk()
            ->assertJson(['message' => 'تم إلغاء تنشيط العميل'])
            ->assertJsonPath('data.is_active', false);
        $this->assertDatabaseHas('customers', ['id' => $customer->id, 'is_active' => false]);
    }

    public function test_activation_can_reactivate_a_customer(): void
    {
        // Arrange
        $customer = Customer::factory()->inactive()->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/customers/{$customer->id}/activation", ['is_active' => true]);

        // Assert
        $response->assertOk()
            ->assertJson(['message' => 'تم تنشيط العميل'])
            ->assertJsonPath('data.is_active', true);
        $this->assertDatabaseHas('customers', ['id' => $customer->id, 'is_active' => true]);
    }

    public function test_activation_requires_the_flag(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/customers/{$customer->id}/activation", []);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('is_active');
    }

    public function test_activation_requires_authentication(): void
    {
        // Arrange
        $customer = Customer::factory()->create();

        // Act
        $response = $this->patchJson("/api/v1/customers/{$customer->id}/activation", ['is_active' => false]);

        // Assert
        $response->assertStatus(401);
    }

    // ─────────────────────────── deletion is not offered ───────────────────────────

    public function test_customers_cannot_be_deleted(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $headers = $this->auth();

        // Act — deactivation replaces deletion, so the route does not exist at all.
        $response = $this->withHeaders($headers)->deleteJson("/api/v1/customers/{$customer->id}");

        // Assert
        $response->assertStatus(405);
        $this->assertDatabaseHas('customers', ['id' => $customer->id]);
    }

    // ─────────────────────────── relation integrity ───────────────────────────

    public function test_deleting_a_customer_in_the_database_cascades_to_its_shops(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        CustomerShop::factory()->count(2)->create(['customer_id' => $customer->id]);

        // Act
        $customer->delete();

        // Assert
        $this->assertDatabaseCount('customer_shops', 0);
    }
}
