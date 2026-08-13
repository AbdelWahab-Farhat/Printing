<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * التصنيفات — the headings the catalogue is organised under: أكياس, علب وكراتين, ستيكرات.
 *
 * The rule this feature exists to keep: **a category any product points at cannot be deleted.**
 * Deleting is soft, so the row would survive and the products would keep pointing at it while
 * the API stopped returning it — a heading nobody can name or restore. Deactivating is what the
 * person actually wants.
 *
 * Arrange - Act - Assert throughout.
 */
class ProductCategoryTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, string>
     */
    private function auth(): array
    {
        $user = User::factory()->create();

        Role::findOrCreate(RoleName::Admin->value, 'web');
        $user->syncRoles([RoleName::Admin->value]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** Somebody who may read the catalogue and nothing more. */
    private function readerHeaders(): array
    {
        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewProducts->value);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    // ─────────────────────────── the list ───────────────────────────

    public function test_categories_come_back_in_the_catalogues_own_order(): void
    {
        // Arrange
        $headers = $this->auth();
        ProductCategory::factory()->create(['name' => 'ستيكرات', 'sort_order' => 3]);
        ProductCategory::factory()->create(['name' => 'أكياس', 'sort_order' => 1]);
        ProductCategory::factory()->create(['name' => 'علب وكراتين', 'sort_order' => 2]);

        // Act
        $response = $this->getJson('/api/v1/product-categories', $headers);

        // Assert — the business's order, not the alphabet's: Arabic collation differs between
        // databases and would bury the category most products are in.
        $response->assertOk()
            ->assertJsonPath('data.0.name', 'أكياس')
            ->assertJsonPath('data.1.name', 'علب وكراتين')
            ->assertJsonPath('data.2.name', 'ستيكرات');
    }

    public function test_each_row_says_how_many_products_are_under_it(): void
    {
        // Arrange
        $headers = $this->auth();
        $bags = ProductCategory::factory()->create(['name' => 'أكياس']);
        Product::factory()->count(2)->create(['product_category_id' => $bags->id]);

        // Act
        $response = $this->getJson('/api/v1/product-categories', $headers);

        // Assert — the same number that decides whether a delete is refused, so the screen can
        // say so before the button is pressed.
        $response->assertOk()->assertJsonPath('data.0.products_count', 2);
    }

    public function test_a_picker_can_ask_for_the_live_ones_only(): void
    {
        // Arrange
        $headers = $this->auth();
        ProductCategory::factory()->create(['name' => 'أكياس']);
        ProductCategory::factory()->inactive()->create(['name' => 'تصنيف قديم']);

        // Act
        $response = $this->getJson('/api/v1/product-categories?is_active=1', $headers);

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.name', 'أكياس');
    }

    // ─────────────────────────── creating and editing ───────────────────────────

    public function test_an_administrator_adds_a_category(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->postJson('/api/v1/product-categories', [
            'name' => 'أكياس',
            'description' => 'تشكيلة أكياس مخصصة للتغليف والشحن',
            'sort_order' => 1,
        ], $headers);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.name', 'أكياس')
            ->assertJsonPath('data.description', 'تشكيلة أكياس مخصصة للتغليف والشحن')
            // Offered the moment it is created; hiding one is a later, deliberate act.
            ->assertJsonPath('data.is_active', true)
            ->assertJsonPath('data.products_count', 0);
    }

    public function test_the_same_name_twice_is_refused(): void
    {
        // Arrange
        $headers = $this->auth();
        ProductCategory::factory()->create(['name' => 'أكياس']);

        // Act
        $response = $this->postJson('/api/v1/product-categories', ['name' => 'أكياس'], $headers);

        // Assert — a readable 422, not the 500 a bare constraint violation would produce.
        $response->assertStatus(422)->assertJsonValidationErrors('name');
    }

    public function test_a_name_freed_by_a_delete_can_be_used_again(): void
    {
        // Arrange — the partial unique index and the `withoutTrashed` rule have to agree, or one
        // of them answers 500 where the other answers a message.
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'أكياس']);
        $this->deleteJson("/api/v1/product-categories/{$category->id}", [], $headers)->assertOk();

        // Act
        $response = $this->postJson('/api/v1/product-categories', ['name' => 'أكياس'], $headers);

        // Assert
        $response->assertCreated();
    }

    public function test_renaming_applies_to_the_products_already_under_it(): void
    {
        // Arrange — a label, not a snapshot: fixing a heading spelt wrong fixes it everywhere.
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'ستكرات']);
        $product = Product::factory()->create(['product_category_id' => $category->id]);

        // Act
        $response = $this->putJson("/api/v1/product-categories/{$category->id}", [
            'name' => 'ستيكرات ومطبوعات أخرى',
        ], $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.name', 'ستيكرات ومطبوعات أخرى');
        $this->assertSame('ستيكرات ومطبوعات أخرى', $product->fresh()->productCategory->name);
    }

    public function test_a_category_keeping_its_own_name_does_not_collide_with_itself(): void
    {
        // Arrange
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'أكياس']);

        // Act — the description changes; the name is re-sent unchanged.
        $response = $this->putJson("/api/v1/product-categories/{$category->id}", [
            'name' => 'أكياس',
            'description' => 'وصف جديد',
        ], $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.description', 'وصف جديد');
    }

    // ─────────────────────────── retiring and removing ───────────────────────────

    public function test_deactivating_hides_a_category_without_touching_its_products(): void
    {
        // Arrange
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'أكياس']);
        $product = Product::factory()->create(['product_category_id' => $category->id]);

        // Act
        $response = $this->patchJson(
            "/api/v1/product-categories/{$category->id}/activation",
            ['is_active' => false],
            $headers,
        );

        // Assert — it leaves the pickers; the product keeps saying what it says.
        $response->assertOk()->assertJsonPath('data.is_active', false);
        $this->assertSame($category->id, $product->fresh()->product_category_id);
    }

    public function test_a_category_nothing_points_at_can_be_deleted(): void
    {
        // Arrange — the row that should never have existed: a typo, a duplicate.
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'خطأ إملائي']);

        // Act
        $response = $this->deleteJson("/api/v1/product-categories/{$category->id}", [], $headers);

        // Assert — soft, like every delete here: the row and its history survive.
        $response->assertOk();
        $this->assertSoftDeleted('product_categories', ['id' => $category->id]);
    }

    public function test_a_category_a_product_points_at_is_refused(): void
    {
        // Arrange
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'أكياس']);
        Product::factory()->create(['product_category_id' => $category->id]);

        // Act
        $response = $this->deleteJson("/api/v1/product-categories/{$category->id}", [], $headers);

        // Assert — and the message says what to do instead, because "no" on its own is a dead end.
        $response->assertStatus(422);
        $this->assertStringContainsString('أوقفه بدل حذفه', (string) $response->json('message'));
        $this->assertDatabaseHas('product_categories', ['id' => $category->id, 'deleted_at' => null]);
    }

    public function test_a_deleted_product_still_holds_its_category_back(): void
    {
        // Arrange — a soft-deleted product can be restored, and a category removed meanwhile
        // would leave it pointing at nothing.
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'أكياس']);
        $product = Product::factory()->create(['product_category_id' => $category->id]);
        $product->delete();

        // Act
        $response = $this->deleteJson("/api/v1/product-categories/{$category->id}", [], $headers);

        // Assert
        $response->assertStatus(422);
    }

    // ─────────────────────────── who may do what ───────────────────────────

    public function test_a_reader_may_list_but_not_change(): void
    {
        // Arrange — no pair of its own: whoever reads products needs the headings to read them
        // by, and whoever maintains products maintains the headings.
        $headers = $this->readerHeaders();
        ProductCategory::factory()->create(['name' => 'أكياس']);

        // Act - Assert
        $this->getJson('/api/v1/product-categories', $headers)->assertOk();
        $this->postJson('/api/v1/product-categories', ['name' => 'جديد'], $headers)->assertForbidden();
    }

    // ─────────────────────────── on the product itself ───────────────────────────

    public function test_a_product_cannot_be_saved_without_a_category(): void
    {
        // Arrange
        $headers = $this->auth();

        // Act
        $response = $this->post('/api/v1/products', [
            'name' => 'أكياس الشحن',
            'category' => 'printed',
            'pricing_unit' => 'piece',
            'pricing_mode' => 'tiered',
            'min_order_quantity' => 100,
            'image' => UploadedFile::fake()->image('bag.jpg'),
        ], $headers);

        // Assert — required from today on, whatever the column allows for the rows that predate
        // the feature.
        $response->assertStatus(422)->assertJsonValidationErrors('product_category_id');
    }

    public function test_a_product_carries_its_category_in_the_response(): void
    {
        // Arrange
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'أكياس']);

        // Act
        $response = $this->post('/api/v1/products', [
            'name' => 'أكياس الشحن',
            'category' => 'printed',
            'product_category_id' => $category->id,
            'pricing_unit' => 'piece',
            'pricing_mode' => 'tiered',
            'min_order_quantity' => 100,
            'image' => UploadedFile::fake()->image('bag.jpg'),
        ], $headers);

        // Assert — the whole object, so a list draws the heading without a request per row.
        $response->assertCreated()
            ->assertJsonPath('data.product_category.id', $category->id)
            ->assertJsonPath('data.product_category.name', 'أكياس');
    }

    public function test_a_category_that_was_deleted_cannot_be_assigned(): void
    {
        // Arrange — a product pointing at a hidden row is worse than one with none.
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'أكياس']);
        $category->delete();

        // Act
        $response = $this->post('/api/v1/products', [
            'name' => 'أكياس الشحن',
            'category' => 'printed',
            'product_category_id' => $category->id,
            'pricing_unit' => 'piece',
            'pricing_mode' => 'tiered',
            'min_order_quantity' => 100,
            'image' => UploadedFile::fake()->image('bag.jpg'),
        ], $headers);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('product_category_id');
    }

    public function test_the_products_list_can_be_narrowed_to_one_category(): void
    {
        // Arrange
        $headers = $this->auth();
        $bags = ProductCategory::factory()->create(['name' => 'أكياس']);
        $boxes = ProductCategory::factory()->create(['name' => 'علب']);
        Product::factory()->create(['name' => 'كيس ورقي', 'product_category_id' => $bags->id]);
        Product::factory()->create(['name' => 'كرتونة شحن', 'product_category_id' => $boxes->id]);

        // Act
        $response = $this->getJson("/api/v1/products?product_category_id={$bags->id}", $headers);

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'كيس ورقي');
    }

    public function test_an_empty_category_filter_means_every_category(): void
    {
        // Arrange — `?product_category_id=` with nothing after it is «الكل», not «التصنيف رقم صفر».
        $headers = $this->auth();
        Product::factory()->count(2)->create();

        // Act
        $response = $this->getJson('/api/v1/products?product_category_id=', $headers);

        // Assert
        $response->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_a_categorys_history_is_readable(): void
    {
        // Arrange
        $headers = $this->auth();
        $category = ProductCategory::factory()->create(['name' => 'أكياس']);
        $this->putJson("/api/v1/product-categories/{$category->id}", ['name' => 'أكياس ورقية'], $headers)
            ->assertOk();

        // Act
        $response = $this->getJson("/api/v1/product-categories/{$category->id}/logs", $headers);

        // Assert — the project rule: every model soft-deletes and every model has a `/logs`.
        $response->assertOk();
        $this->assertNotEmpty($response->json('data'));
    }
}
