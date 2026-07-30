<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * The product catalogue endpoints.
 *
 * Arrange - Act - Assert throughout.
 */
class ProductTest extends TestCase
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
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'slug' => 'shipping-bag',
            'name' => 'أكياس الشحن',
            'category' => 'printed',
            'pricing_unit' => 'piece',
            'pricing_mode' => 'tiered',
            'min_order_quantity' => 100,
        ], $overrides);
    }

    // ─────────────────────────── create ───────────────────────────

    public function test_create_stores_the_product_with_its_sizes_and_price_list(): void
    {
        // Arrange
        $headers = $this->auth();
        $payload = $this->payload([
            'features' => ['مقاومة للماء والتمزق', 'لاصق قوي واحترافي'],
            'variants' => [
                [
                    'label' => '25*35',
                    'width_cm' => 25,
                    'height_cm' => 35,
                    'price_tiers' => [
                        ['min_quantity' => 1, 'unit_price' => '1.10'],
                        ['min_quantity' => 300, 'unit_price' => '0.95'],
                        ['min_quantity' => 1000, 'unit_price' => '0.85'],
                    ],
                ],
            ],
        ]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/products', $payload);

        // Assert
        $response->assertCreated()
            ->assertJson([
                'status' => true,
                'message' => 'تم إضافة المنتج بنجاح',
                'data' => [
                    'slug' => 'shipping-bag',
                    'category' => 'printed',
                    'category_label' => 'مطبوعة',
                    'pricing_unit' => 'piece',
                    'pricing_mode' => 'tiered',
                    'has_listed_prices' => true,
                    'is_active' => true,
                ],
            ])
            ->assertJsonCount(1, 'data.variants')
            ->assertJsonCount(3, 'data.variants.0.price_tiers')
            ->assertJsonPath('data.variants.0.price_tiers.0.unit_price', '1.100')
            ->assertJsonPath('data.features.0', 'مقاومة للماء والتمزق');

        $this->assertDatabaseHas('products', ['slug' => 'shipping-bag']);
        $this->assertDatabaseCount('product_price_tiers', 3);
    }

    public function test_create_accepts_a_per_kilo_product_with_a_fractional_minimum(): void
    {
        // Arrange
        $headers = $this->auth();
        $payload = $this->payload([
            'slug' => 'general-shipping-bag',
            'name' => 'أكياس الشحن السادة',
            'category' => 'general',
            'pricing_unit' => 'kilogram',
            'min_order_quantity' => '2.5',
            'variants' => [
                ['label' => 'سادة', 'price_tiers' => [['min_quantity' => 1, 'unit_price' => '32']]],
            ],
        ]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/products', $payload);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.pricing_unit', 'kilogram')
            ->assertJsonPath('data.pricing_unit_label', 'كيلوغرام')
            ->assertJsonPath('data.category_label', 'سادة')
            ->assertJsonPath('data.min_order_quantity', '2.500');
    }

    public function test_create_rejects_a_fractional_minimum_for_a_per_piece_product(): void
    {
        // Arrange — you cannot require a minimum of two and a half bags.
        $headers = $this->auth();
        $payload = $this->payload(['pricing_unit' => 'piece', 'min_order_quantity' => '2.5']);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/products', $payload);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('min_order_quantity');
    }

    public function test_create_refuses_to_put_prices_on_a_quote_only_product(): void
    {
        // Arrange — a listed price would contradict "price on request".
        $headers = $this->auth();
        $payload = $this->payload([
            'slug' => 'paper-bag-3d',
            'pricing_mode' => 'quote_on_request',
            'min_order_quantity' => 200,
            'variants' => [
                ['label' => 'حسب الطلب', 'price_tiers' => [['min_quantity' => 1, 'unit_price' => '5.00']]],
            ],
        ]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/products', $payload);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('variants.0.price_tiers');
    }

    public function test_create_allows_a_quote_only_product_without_prices(): void
    {
        // Arrange
        $headers = $this->auth();
        $payload = $this->payload([
            'slug' => 'paper-bag-3d',
            'name' => 'أكياس ورقية 3D',
            'pricing_mode' => 'quote_on_request',
            'min_order_quantity' => 200,
            'variants' => [['label' => 'حسب الطلب']],
        ]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/products', $payload);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.pricing_mode', 'quote_on_request')
            ->assertJsonPath('data.pricing_mode_label', 'السعر حسب الطلب')
            ->assertJsonPath('data.has_listed_prices', false)
            ->assertJsonCount(0, 'data.variants.0.price_tiers');
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    #[DataProvider('invalidProductCases')]
    public function test_create_rejects_invalid_input(array $overrides, string $invalidField): void
    {
        // Arrange
        $headers = $this->auth();
        $payload = $this->payload($overrides);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/products', $payload);

        // Assert
        $response->assertStatus(422)
            ->assertJson(['status' => false, 'data' => null])
            ->assertJsonValidationErrors($invalidField);
    }

    /**
     * @return array<string, array{array<string, mixed>, string}>
     */
    public static function invalidProductCases(): array
    {
        return [
            'slug missing' => [['slug' => ''], 'slug'],
            'slug with spaces' => [['slug' => 'shipping bag'], 'slug'],
            'slug with arabic' => [['slug' => 'كيس'], 'slug'],
            'slug uppercase' => [['slug' => 'Shipping-Bag'], 'slug'],
            'name missing' => [['name' => ''], 'name'],
            'unknown category' => [['category' => 'plastic'], 'category'],
            'unknown pricing unit' => [['pricing_unit' => 'metre'], 'pricing_unit'],
            'unknown pricing mode' => [['pricing_mode' => 'auction'], 'pricing_mode'],
            'minimum of zero' => [['min_order_quantity' => 0], 'min_order_quantity'],
            'negative minimum' => [['min_order_quantity' => -5], 'min_order_quantity'],
            'variant without a label' => [['variants' => [['width_cm' => 25]]], 'variants.0.label'],
            'negative unit price' => [
                ['variants' => [['label' => '25*35', 'price_tiers' => [['min_quantity' => 1, 'unit_price' => -1]]]]],
                'variants.0.price_tiers.0.unit_price',
            ],
            'tier without a price' => [
                ['variants' => [['label' => '25*35', 'price_tiers' => [['min_quantity' => 1]]]]],
                'variants.0.price_tiers.0.unit_price',
            ],
        ];
    }

    public function test_create_rejects_a_duplicate_slug(): void
    {
        // Arrange
        Product::factory()->create(['slug' => 'shipping-bag']);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/products', $this->payload());

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('slug');
    }

    public function test_create_requires_authentication(): void
    {
        // Act
        $response = $this->postJson('/api/v1/products', $this->payload());

        // Assert
        $response->assertStatus(401);
    }

    // ─────────────────────────── list ───────────────────────────

    public function test_index_returns_a_paginated_catalogue_in_sort_order(): void
    {
        // Arrange
        Product::factory()->create(['slug' => 'third', 'sort_order' => 3]);
        Product::factory()->create(['slug' => 'first', 'sort_order' => 1]);
        Product::factory()->create(['slug' => 'second', 'sort_order' => 2]);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/products');

        // Assert
        $response->assertOk()
            ->assertJsonStructure([
                'status',
                'message',
                'data' => [['id', 'slug', 'name', 'category', 'pricing_unit', 'pricing_mode', 'variants']],
                'meta' => ['current_page', 'per_page', 'last_page', 'total'],
            ]);

        $this->assertSame(['first', 'second', 'third'], array_column($response->json('data'), 'slug'));
    }

    public function test_index_handles_an_empty_catalogue(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/products');

        // Assert
        $response->assertOk()->assertJsonPath('data', [])->assertJsonPath('meta.total', 0);
    }

    public function test_index_paginates_and_caps_the_page_size(): void
    {
        // Arrange
        Product::factory()->count(5)->create();
        $headers = $this->auth();

        // Act
        $paged = $this->withHeaders($headers)->getJson('/api/v1/products?per_page=2');
        $capped = $this->withHeaders($headers)->getJson('/api/v1/products?per_page=100000');

        // Assert
        $paged->assertOk()->assertJsonCount(2, 'data')->assertJsonPath('meta.last_page', 3);
        $capped->assertOk()->assertJsonPath('meta.per_page', 100);
    }

    public function test_index_filters_by_category_unit_and_mode(): void
    {
        // Arrange
        $printed = Product::factory()->create(['slug' => 'printed-one']);
        $general = Product::factory()->perKilogram()->create(['slug' => 'general-one']);
        $quoted = Product::factory()->quoteOnRequest()->create(['slug' => 'quoted-one']);
        $headers = $this->auth();

        // Act
        $byCategory = $this->withHeaders($headers)->getJson('/api/v1/products?category=general');
        $byUnit = $this->withHeaders($headers)->getJson('/api/v1/products?pricing_unit=kilogram');
        $byMode = $this->withHeaders($headers)->getJson('/api/v1/products?pricing_mode=quote_on_request');

        // Assert
        $this->assertSame([$general->id], array_column($byCategory->json('data'), 'id'));
        $this->assertSame([$general->id], array_column($byUnit->json('data'), 'id'));
        $this->assertSame([$quoted->id], array_column($byMode->json('data'), 'id'));
        $this->assertNotContains($printed->id, array_column($byCategory->json('data'), 'id'));
    }

    public function test_index_searches_by_name_and_slug(): void
    {
        // Arrange
        $target = Product::factory()->create(['slug' => 'shipping-bag', 'name' => 'أكياس الشحن']);
        Product::factory()->create(['slug' => 'paper-bag', 'name' => 'أكياس ورقية']);
        $headers = $this->auth();

        foreach (['الشحن', 'shipping'] as $term) {
            // Act
            $response = $this->withHeaders($headers)->getJson('/api/v1/products?search='.urlencode($term));

            // Assert
            $response->assertOk();
            $this->assertSame(
                [$target->id],
                array_column($response->json('data'), 'id'),
                "Search term [{$term}] should match only the target product.",
            );
        }
    }

    public function test_index_filters_by_activity(): void
    {
        // Arrange
        $active = Product::factory()->create();
        $inactive = Product::factory()->inactive()->create();
        $headers = $this->auth();

        // Act
        $activeOnly = $this->withHeaders($headers)->getJson('/api/v1/products?is_active=1');
        $inactiveOnly = $this->withHeaders($headers)->getJson('/api/v1/products?is_active=0');

        // Assert
        $this->assertSame([$active->id], array_column($activeOnly->json('data'), 'id'));
        $this->assertSame([$inactive->id], array_column($inactiveOnly->json('data'), 'id'));
    }

    public function test_index_requires_authentication(): void
    {
        // Act
        $response = $this->getJson('/api/v1/products');

        // Assert
        $response->assertStatus(401);
    }

    // ─────────────────────────── show ───────────────────────────

    public function test_show_returns_the_product_with_variants_and_prices(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->from(1, '1.100')->create(['product_variant_id' => $variant->id]);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/products/{$product->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.id', $product->id)
            ->assertJsonCount(1, 'data.variants')
            ->assertJsonPath('data.variants.0.price_tiers.0.unit_price', '1.100');
    }

    public function test_show_returns_404_for_an_unknown_product(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/products/999999');

        // Assert
        $response->assertNotFound()->assertJson(['status' => false, 'data' => null]);
    }

    // ─────────────────────────── update ───────────────────────────

    public function test_update_changes_the_basic_fields(): void
    {
        // Arrange
        $product = Product::factory()->create(['slug' => 'old-slug', 'name' => 'قديم']);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/products/{$product->id}",
            $this->payload(['slug' => 'new-slug', 'name' => 'جديد']),
        );

        // Assert
        $response->assertOk()
            ->assertJson(['message' => 'تم تحديث المنتج بنجاح'])
            ->assertJsonPath('data.slug', 'new-slug')
            ->assertJsonPath('data.name', 'جديد');
    }

    public function test_update_allows_a_product_to_keep_its_own_slug(): void
    {
        // Arrange
        $product = Product::factory()->create(['slug' => 'shipping-bag']);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/products/{$product->id}", $this->payload(['slug' => 'shipping-bag']));

        // Assert
        $response->assertOk()->assertJsonPath('data.slug', 'shipping-bag');
    }

    public function test_update_rejects_a_slug_taken_by_another_product(): void
    {
        // Arrange
        $product = Product::factory()->create(['slug' => 'mine']);
        Product::factory()->create(['slug' => 'theirs']);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/products/{$product->id}", $this->payload(['slug' => 'theirs']));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('slug');
    }

    public function test_update_without_is_active_does_not_reactivate_a_deactivated_product(): void
    {
        // Arrange
        $product = Product::factory()->inactive()->create();
        $headers = $this->auth();

        // Act — payload deliberately omits is_active.
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/products/{$product->id}", $this->payload());

        // Assert
        $response->assertOk()->assertJsonPath('data.is_active', false);
    }

    public function test_update_leaves_the_price_list_alone_when_variants_are_absent(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->from(1, '1.100')->create(['product_variant_id' => $variant->id]);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/products/{$product->id}", $this->payload());

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data.variants');
        $this->assertDatabaseCount('product_price_tiers', 1);
    }

    public function test_update_syncs_variants_updating_adding_and_removing_in_one_call(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $kept = ProductVariant::factory()->create(['product_id' => $product->id, 'label' => '25*35']);
        $removed = ProductVariant::factory()->create(['product_id' => $product->id, 'label' => '99*99']);
        ProductPriceTier::factory()->from(1, '9.999')->create(['product_variant_id' => $kept->id]);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/products/{$product->id}",
            $this->payload(['variants' => [
                ['id' => $kept->id, 'label' => '25*35', 'price_tiers' => [['min_quantity' => 1, 'unit_price' => '1.10']]],
                ['label' => '40*50', 'price_tiers' => [['min_quantity' => 1, 'unit_price' => '2.00']]],
            ]]),
        );

        // Assert
        $response->assertOk()->assertJsonCount(2, 'data.variants');

        // The kept variant survived with its id, and its price list was replaced.
        $this->assertDatabaseHas('product_variants', ['id' => $kept->id, 'label' => '25*35']);
        $this->assertDatabaseMissing('product_variants', ['id' => $removed->id]);
        $this->assertDatabaseHas('product_price_tiers', ['product_variant_id' => $kept->id, 'unit_price' => '1.100']);
        $this->assertDatabaseMissing('product_price_tiers', ['unit_price' => '9.999']);
    }

    public function test_update_removing_a_variant_removes_its_prices_too(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->count(3)->create(['product_variant_id' => $variant->id]);
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)
            ->putJson("/api/v1/products/{$product->id}", $this->payload(['variants' => []]));

        // Assert
        $response->assertOk()->assertJsonCount(0, 'data.variants');
        $this->assertDatabaseCount('product_variants', 0);
        $this->assertDatabaseCount('product_price_tiers', 0);
    }

    public function test_update_rejects_a_variant_id_belonging_to_another_product(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $foreign = ProductVariant::factory()->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/products/{$product->id}",
            $this->payload(['variants' => [['id' => $foreign->id, 'label' => 'اختراق']]]),
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('variants.0.id');
        $this->assertDatabaseHas('product_variants', ['id' => $foreign->id, 'label' => $foreign->label]);
    }

    public function test_update_requires_authentication(): void
    {
        // Arrange
        $product = Product::factory()->create();

        // Act
        $response = $this->putJson("/api/v1/products/{$product->id}", $this->payload());

        // Assert
        $response->assertStatus(401);
    }

    // ─────────────────────────── activation ───────────────────────────

    public function test_activation_can_deactivate_and_reactivate_a_product(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $headers = $this->auth();

        // Act
        $off = $this->withHeaders($headers)
            ->patchJson("/api/v1/products/{$product->id}/activation", ['is_active' => false]);
        $on = $this->withHeaders($headers)
            ->patchJson("/api/v1/products/{$product->id}/activation", ['is_active' => true]);

        // Assert
        $off->assertOk()->assertJson(['message' => 'تم إلغاء تنشيط المنتج'])->assertJsonPath('data.is_active', false);
        $on->assertOk()->assertJson(['message' => 'تم تنشيط المنتج'])->assertJsonPath('data.is_active', true);
    }

    public function test_activation_requires_the_flag(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $headers = $this->auth();

        // Act
        $response = $this->withHeaders($headers)->patchJson("/api/v1/products/{$product->id}/activation", []);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('is_active');
    }

    // ─────────────────────────── deletion is not offered ───────────────────────────

    public function test_products_cannot_be_deleted(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $headers = $this->auth();

        // Act — deactivation replaces deletion, so the route does not exist.
        $response = $this->withHeaders($headers)->deleteJson("/api/v1/products/{$product->id}");

        // Assert
        $response->assertStatus(405);
        $this->assertDatabaseHas('products', ['id' => $product->id]);
    }

    // ─────────────────────────── cascade ───────────────────────────

    public function test_deleting_a_product_in_the_database_cascades_to_variants_and_prices(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->count(2)->create(['product_variant_id' => $variant->id]);

        // Act
        $product->delete();

        // Assert
        $this->assertDatabaseCount('product_variants', 0);
        $this->assertDatabaseCount('product_price_tiers', 0);
    }
}
