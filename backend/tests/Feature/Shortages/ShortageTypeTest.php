<?php

declare(strict_types=1);

namespace Tests\Feature\Shortages;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\ShortageRevision;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\OrderService;
use App\Domain\Shortage\Actions\SyncShortagesFromOrder;
use App\Domain\Shortage\Enums\ShortageSource;
use App\Domain\Shortage\Enums\ShortageType;
use App\Domain\Shortage\Models\Shortage;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * What kind of thing is short, beside who wrote the row down.
 *
 * **Two axes, and one column could not hold them.** `source` says «يدوي» or «من طلبية» — who owns
 * the numbers. `type` says «ورق طباعة», «حبر», «صيانة» — what the shop is out of. A shortage of
 * paper somebody typed by hand is both, and collapsing the pair would make «أرِني كل نواقص الورق»
 * unanswerable without also knowing who entered each row.
 *
 * **The one value that is not a free choice is «نقص طلبية».** It belongs to the sync, and the
 * pairing is held by the form, the enum and a CHECK on the table — the three layers RULES §8 asks
 * for. Without it a clerk could put «نقص طلبية» on a roll of tape and the list's one readable
 * column would start lying.
 *
 * Arrange - Act - Assert throughout.
 */
class ShortageTypeTest extends TestCase
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
    private function clerk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewShortages->value,
            PermissionName::ManageShortages->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'ورق A4',
            'unit' => PricingUnit::Piece->value,
            'required_quantity' => '3000',
        ], $overrides);
    }

    private function orderBornShortage(): Shortage
    {
        $order = Order::factory()->status(OrderStatus::Shortage)->create();
        $item = OrderItem::factory()->for($order)->create(['quantity' => '300.000']);

        app(OrderService::class)->setShortages(
            $order->refresh(),
            [$item->getKey() => '30'],
            null,
            ShortageRevision::Declared,
        );

        app(SyncShortagesFromOrder::class)((int) $order->getKey(), ShortageRevision::Declared);

        return Shortage::query()->where('order_item_id', $item->getKey())->firstOrFail();
    }

    // ── writing one by hand ─────────────────────────────────────────────────────────────

    public function test_a_hand_written_shortage_carries_the_type_it_was_given(): void
    {
        // Arrange
        $headers = $this->clerk();

        // Act
        $response = $this->postJson('/api/v1/shortages', $this->payload([
            'type' => ShortageType::PrintingPaper->value,
        ]), $headers);

        // Assert — the value and the label, because the screen prints one and filters on the
        // other. Exactly the arrangement `source` beside it already has.
        $response->assertCreated()
            ->assertJsonPath('data.type', ShortageType::PrintingPaper->value)
            ->assertJsonPath('data.type_label', 'ورق طباعة')
            ->assertJsonPath('data.source', ShortageSource::Manual->value);
    }

    public function test_a_type_nobody_chose_is_other_rather_than_a_refusal(): void
    {
        // Arrange — what gets written down by hand is often what no list anticipated, and forcing
        // the nearest wrong category would put an invention in the column that reports «على ماذا
        // ننفق؟». The same reasoning the optional product link follows.
        $headers = $this->clerk();

        // Act
        $response = $this->postJson('/api/v1/shortages', $this->payload(), $headers);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.type', ShortageType::Other->value)
            ->assertJsonPath('data.type_label', 'أخرى');
    }

    public function test_nobody_may_type_the_value_that_belongs_to_the_sync(): void
    {
        // Arrange
        $headers = $this->clerk();

        // Act — «نقص طلبية» claimed by hand, on a row with no order behind it at all.
        $response = $this->postJson('/api/v1/shortages', $this->payload([
            'type' => ShortageType::Order->value,
        ]), $headers);

        // Assert — refused at the form, which is the readable layer. The CHECK below is the
        // guarantee, and the enum's own `isSelectableByHand()` is what the form reads.
        $response->assertStatus(422)->assertJsonValidationErrors('type');
        $this->assertSame(0, Shortage::query()->count());
    }

    // ── one born of an order ────────────────────────────────────────────────────────────

    public function test_an_order_born_shortage_is_stamped_and_never_asked(): void
    {
        // Arrange - Act
        $shortage = $this->orderBornShortage();

        // Assert — `source` and `type` are two halves of one fact, written together by the sync.
        $this->assertSame(ShortageSource::FromOrder, $shortage->source);
        $this->assertSame(ShortageType::Order, $shortage->type);
    }

    public function test_the_database_refuses_the_two_halves_coming_apart(): void
    {
        // Arrange — the guarantee behind the form's 422: a writer that went around the Action
        // entirely still cannot put «نقص طلبية» on a hand-written row.
        $shortage = Shortage::factory()->create();

        // Act - Assert
        $this->expectException(QueryException::class);

        $shortage->forceFill(['type' => ShortageType::Order])->save();
    }

    public function test_the_database_refuses_an_order_born_row_claiming_another_type(): void
    {
        // Arrange — and the same rule from the other direction: a row mirrored from a line is
        // «نقص طلبية» and cannot be filed as stationery.
        $shortage = $this->orderBornShortage();

        // Act - Assert
        $this->expectException(QueryException::class);

        $shortage->forceFill(['type' => ShortageType::Ink])->save();
    }

    // ── reading the list ────────────────────────────────────────────────────────────────

    public function test_the_list_narrows_to_one_type(): void
    {
        // Arrange — «أرِني كل نواقص الورق», the query the column exists for.
        $headers = $this->clerk();

        Shortage::factory()->create(['type' => ShortageType::PrintingPaper, 'name' => 'ورق A4']);
        Shortage::factory()->create(['type' => ShortageType::Ink, 'name' => 'حبر أسود']);
        $this->orderBornShortage();

        // Act
        $response = $this->getJson(
            '/api/v1/shortages?type='.ShortageType::PrintingPaper->value,
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data');
        $this->assertSame('ورق A4', $response->json('data.0.name'));
    }

    public function test_a_type_the_enum_never_heard_of_narrows_nothing(): void
    {
        // Arrange — an unknown value in a query string is a filter nobody asked for, not a 500.
        // `tryFrom` is what makes that true, the same as `source` beside it.
        $headers = $this->clerk();

        Shortage::factory()->create(['type' => ShortageType::Ink]);

        // Act
        $response = $this->getJson('/api/v1/shortages?type=ورق_مقوى', $headers);

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data');
    }
}
