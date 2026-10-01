<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Audit\AuditAttributeLabels;
use App\Domain\Audit\AuditHiddenAttributes;
use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Searching a history by field, and the lines it no longer draws.
 *
 * Two halves of one idea: a history is read to answer «who changed the price?», and it answers
 * faster when it can be asked for prices only, and when the lines nobody reads — a row's place in
 * a list, a cached total, a ticket's read marker — are not drawn in the way. Those lines are
 * still logged; see AuditHiddenAttributes.
 *
 * Arrange - Act - Assert throughout.
 */
class ActivityLogFieldSearchTest extends TestCase
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
    private function auditor(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewActivityLogs->value);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    // ─────────────────────────── the field filter ───────────────────────────

    public function test_a_field_narrows_the_history_to_the_entries_about_it(): void
    {
        // Arrange — a price moved on a tier, and the product's name moved beside it.
        $product = Product::factory()->create(['name' => 'كيس أول']);
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $tier = ProductPriceTier::factory()->create(['product_variant_id' => $variant->id]);
        $tier->update(['unit_price' => '0.900']);
        $product->update(['name' => 'كيس ثانٍ']);
        $headers = $this->auditor();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/products/{$product->id}/logs?field=product_price_tier:unit_price");

        // Assert — the tier's creation (it was created with a price) and the change, and
        // nothing about the name.
        $response->assertOk()->assertJsonCount(2, 'data');
        $this->assertSame(['product_price_tier'], array_values(array_unique(array_column($response->json('data'), 'subject_type'))));
        $this->assertSame(['updated', 'created'], array_column($response->json('data'), 'event'));
        $this->assertSame('0.900', $response->json('data.0.changes.attributes.unit_price'));

        // The chips count the same narrowed trail.
        $response->assertJsonPath('meta.event_counts.created', 1)
            ->assertJsonPath('meta.event_counts.updated', 1);
    }

    public function test_a_creation_that_left_the_field_empty_does_not_match_it(): void
    {
        // Arrange — created with no category, then given one.
        $product = Product::factory()->create();
        $category = ProductCategory::factory()->create();
        $product->update(['product_category_id' => $category->id]);
        $headers = $this->auditor();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/products/{$product->id}/logs?field=product:product_category_id");

        // Assert — only the update. A creation that said nothing about the category is not an
        // answer to «who set the category?».
        $response->assertOk()->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.event', 'updated');
    }

    public function test_the_global_feed_takes_the_same_field(): void
    {
        // Arrange
        $product = Product::factory()->create(['name' => 'كيس أول']);
        $product->update(['name' => 'كيس ثانٍ']);
        $other = Product::factory()->create();
        $other->update(['description' => 'وصف جديد']);
        $headers = $this->auditor();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/logs?field=product:description&event=updated');

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.subject_id', $other->id);
    }

    // ─────────────────────────── the suggestions ───────────────────────────

    public function test_the_history_offers_the_fields_its_entries_touch(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->create(['product_variant_id' => $variant->id]);
        $headers = $this->auditor();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/products/{$product->id}/logs");

        // Assert — keyed so the client can send it straight back, labelled so it can be found
        // by typing, and named by whose it is for the labels that read alike.
        $response->assertOk();
        $fields = collect($response->json('meta.fields'))->keyBy('key');

        $this->assertSame(
            [
                'key' => 'product_price_tier:unit_price',
                'label' => AuditAttributeLabels::for(AuditSubject::ProductPriceTier)['unit_price'],
                'subject_label' => AuditSubject::ProductPriceTier->label(),
            ],
            $fields->get('product_price_tier:unit_price'),
        );
        $this->assertTrue($fields->has('product:name'));

        // Nothing hidden, and nothing the product was never given.
        $this->assertFalse($fields->has('product:slug'));
        $this->assertFalse($fields->has('product:sort_order'));
        $this->assertFalse($fields->has('product:product_category_id'));
    }

    public function test_every_offered_field_is_one_the_filter_accepts(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->create(['product_variant_id' => $variant->id]);
        $headers = $this->auditor();
        $fields = $this->withHeaders($headers)->getJson("/api/v1/products/{$product->id}/logs")->json('meta.fields');

        // Act & Assert — a suggestion that 422s, or leads to an empty page, is a broken promise.
        $this->assertNotEmpty($fields);

        foreach ($fields as $field) {
            $response = $this->withHeaders($headers)
                ->getJson("/api/v1/products/{$product->id}/logs?field={$field['key']}");

            $response->assertOk();
            $this->assertNotEmpty($response->json('data'), $field['key']);
        }
    }

    // ─────────────────────────── the lines nobody reads ───────────────────────────

    public function test_an_update_made_only_of_noise_is_not_listed_or_counted(): void
    {
        // Arrange — dragged down the list, and nothing else.
        $product = Product::factory()->create();
        $product->update(['sort_order' => 9]);
        $headers = $this->auditor();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/products/{$product->id}/logs");

        // Assert — the creation alone; the reorder is still in the table.
        $response->assertOk()->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.event', 'created')
            ->assertJsonPath('meta.event_counts.updated', 0);
        $this->assertDatabaseHas('activity_log', ['subject_id' => $product->id, 'event' => 'updated']);
    }

    public function test_an_update_with_something_real_in_it_keeps_that_and_loses_the_noise(): void
    {
        // Arrange
        $product = Product::factory()->create(['name' => 'كيس أول']);
        $product->update(['name' => 'كيس ثانٍ', 'sort_order' => 9]);
        $headers = $this->auditor();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/products/{$product->id}/logs?event=updated");

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.changes.attributes.name', 'كيس ثانٍ')
            ->assertJsonMissingPath('data.0.changes.attributes.sort_order')
            ->assertJsonMissingPath('data.0.attribute_labels.sort_order');
    }

    public function test_the_same_column_is_noise_on_one_record_and_not_on_another(): void
    {
        // Arrange — a ticket's read marker, and a column of the same name nowhere else.
        $marker = ['staff_read_at' => '2026-09-27T09:10:00Z', 'subject' => 'طباعة'];

        // Act
        $onTicket = AuditHiddenAttributes::strip($marker, AuditSubject::SupportTicket);
        $elsewhere = AuditHiddenAttributes::strip($marker, AuditSubject::Product);

        // Assert
        $this->assertSame(['subject' => 'طباعة'], $onTicket);
        $this->assertSame($marker, $elsewhere);
    }

    public function test_every_noise_column_is_a_real_column_of_a_real_record(): void
    {
        // Arrange — a typo here would hide nothing and fail nowhere, which is the one way this
        // list can rot without anybody noticing.
        $noise = AuditHiddenAttributes::noise();

        // Act & Assert
        foreach ($noise['per_subject'] as $alias => $columns) {
            $subject = AuditSubject::tryFrom($alias);
            $this->assertNotNull($subject, "«{$alias}» is not a subject");

            foreach ($columns as $column) {
                $this->assertArrayHasKey($column, AuditAttributeLabels::for($subject), "{$alias}.{$column}");
            }
        }
    }
}
