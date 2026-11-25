<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Enums\ProductionMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockItemGroup;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * حجم المبيعات وحركة الأكياس over a period.
 *
 * Built through factories rather than the real order lifecycle, exactly as
 * {@see ProfitAndLossReportTest} is and for the same reason: the query is what is under test,
 * not the write paths that filled the columns it reads. The one place that costs something is
 * the weight — `warehouse_quantity` is written by the «جاهزة» transition in real life — so the
 * tests below set it by hand and `OrderWorkflowTest` covers the transition that fills it.
 *
 * Arrange - Act - Assert throughout.
 */
class SalesStatisticsReportTest extends TestCase
{
    use RefreshDatabase;

    private const ENDPOINT = '/api/v1/reports/sales-statistics';

    private const PERIOD = '?from=2026-03-01&to=2026-03-31';

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /** @return array<string, string> */
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function viewer(): array
    {
        return $this->auth(PermissionName::ViewSalesStatisticsReport);
    }

    private function board(): array
    {
        return $this->withHeaders($this->viewer())->getJson(self::ENDPOINT.self::PERIOD)->json('data');
    }

    private function category(ProductionMode $mode): ProductCategory
    {
        return ProductCategory::factory()->create(['production_mode' => $mode]);
    }

    /** An order inside the reported period, recognised on delivery. */
    private function deliveredOrder(): Order
    {
        return Order::factory()->status(OrderStatus::Delivered)->create([
            'delivered_at' => '2026-03-15 10:00:00',
        ]);
    }

    /**
     * One line of one order, on a shelf of the caller's choosing.
     *
     * [$shelf] is passed explicitly wherever a test is about two products drawing on one pile —
     * which is what the type table is built on.
     *
     * @param  array<string, mixed>  $attributes
     */
    private function line(
        Order $order,
        ProductCategory $category,
        PricingUnit $shelfUnit = PricingUnit::Kilogram,
        array $attributes = [],
        ?StockItem $shelf = null,
    ): OrderItem {
        $product = Product::factory()->create(['product_category_id' => $category->getKey()]);
        $shelf ??= StockItem::factory()->unit($shelfUnit)->create();
        $variant = ProductVariant::factory()->create([
            'product_id' => $product->getKey(),
            'stock_item_id' => $shelf->getKey(),
        ]);

        return OrderItem::factory()->for($order)->create(array_merge([
            'product_id' => $product->getKey(),
            'product_variant_id' => $variant->getKey(),
        ], $attributes));
    }

    public function test_reading_the_board_needs_its_own_permission(): void
    {
        // Arrange
        $headers = $this->auth(PermissionName::ViewOrders);

        // Act
        $response = $this->withHeaders($headers)->getJson(self::ENDPOINT.self::PERIOD);

        // Assert
        $response->assertForbidden();
    }

    public function test_the_profit_and_loss_permission_does_not_open_this_board(): void
    {
        // Arrange — a separate grant, so the press may be shown its output without the margin
        $headers = $this->auth(PermissionName::ViewProfitAndLossReport);

        // Act
        $response = $this->withHeaders($headers)->getJson(self::ENDPOINT.self::PERIOD);

        // Assert
        $response->assertForbidden();
    }

    public function test_the_period_is_required(): void
    {
        // Act
        $response = $this->withHeaders($this->viewer())->getJson(self::ENDPOINT);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['from', 'to']);
    }

    public function test_sales_value_splits_plain_from_printed_and_the_parts_add_up(): void
    {
        // Arrange
        $order = $this->deliveredOrder();
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '1000.000',
            'warehouse_quantity' => '20.500', 'line_total' => '1800.00',
        ]);
        $this->line($order, $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '40.000', 'line_total' => '1200.00',
        ]);

        // Act
        $data = $this->board();

        // Assert
        $this->assertSame('1800.00', $data['sales_value']['printed']);
        $this->assertSame('1200.00', $data['sales_value']['plain']);
        $this->assertSame('3000.00', $data['sales_value']['total']);
        $this->assertSame(1, $data['orders_counted']);
    }

    public function test_printed_weight_is_the_measured_warehouse_quantity_not_the_piece_count(): void
    {
        // Arrange — 1000 bags that weighed 20.5 kg on the way into «جاهزة»
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '1000.000',
            'warehouse_quantity' => '20.500', 'line_total' => '1800.00',
        ]);

        // Act
        $data = $this->board();

        // Assert — the scale's figure, never the 1000
        $this->assertSame('20.500', $data['weight_comparison']['printed_kg']);
        $this->assertSame(1000, $data['printed_pieces']['count']);
        $this->assertSame('100.0', $data['weight_comparison']['weight_coverage_percent']);
    }

    public function test_plain_weight_is_the_quantity_because_the_line_was_sold_by_weight(): void
    {
        // Arrange — no scale reading: sold by the kilo off a shelf counted in kilos
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '40.000',
            'warehouse_quantity' => null, 'line_total' => '1200.00',
        ]);

        // Act
        $data = $this->board();

        // Assert
        $this->assertSame('40.000', $data['weight_comparison']['plain_kg']);
        $this->assertSame('0.000', $data['weight_comparison']['printed_kg']);
        $this->assertSame(0, $data['printed_pieces']['count']);
    }

    public function test_a_shelf_counted_in_pieces_earns_money_but_weighs_nothing(): void
    {
        // Arrange — أكياس ورقية عادية: a printed bag whose pile is counted by the piece, so
        // nobody ever weighed it. The only bag in the catalogue in that position.
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::InHouse), PricingUnit::Piece, [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '500.000',
            'warehouse_quantity' => null, 'line_total' => '600.00',
        ]);

        // Act
        $data = $this->board();

        // Assert — its money counts, and counts as مطبوع…
        $this->assertSame('600.00', $data['sales_value']['printed']);
        $this->assertSame('600.00', $data['sales_value']['total']);
        $this->assertSame(500, $data['printed_pieces']['count']);

        // …and it is absent from every weight, rather than weighing its own piece count
        $this->assertSame('0.000', $data['weight_comparison']['printed_kg']);
        $this->assertSame('0.000', $data['weight_comparison']['total_kg']);
        $this->assertSame('0.0', $data['weight_comparison']['weight_coverage_percent']);

        // Still a row of its own, so the type table adds up to the revenue above it
        $this->assertCount(1, $data['by_type']);
        $this->assertSame('600.00', $data['by_type'][0]['value']);
        $this->assertSame('0.000', $data['by_type'][0]['weight_kg']);
    }

    public function test_the_share_of_printed_is_reported_against_the_total_weight(): void
    {
        // Arrange
        $order = $this->deliveredOrder();
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '1000.000',
            'warehouse_quantity' => '285.000', 'line_total' => '1800.00',
        ]);
        $this->line($order, $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '450.000', 'line_total' => '1200.00',
        ]);

        // Act
        $data = $this->board();

        // Assert — 285 of 735
        $this->assertSame('735.000', $data['weight_comparison']['total_kg']);
        $this->assertSame('38.7', $data['weight_comparison']['printed_share_percent']);
    }

    public function test_a_shortage_is_subtracted_from_the_piece_count(): void
    {
        // Arrange — 500 ordered, 100 never delivered
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '500.000',
            'shortage_quantity' => '100.000', 'warehouse_quantity' => '8.000', 'line_total' => '440.00',
        ]);

        // Act
        $data = $this->board();

        // Assert — what was billed, not what was asked for
        $this->assertSame(400, $data['printed_pieces']['count']);
        $this->assertSame('440.00', $data['sales_value']['printed']);
    }

    public function test_a_plain_shortage_is_subtracted_from_the_weight_too(): void
    {
        // Arrange — 40 kg agreed, 5 kg short, and nobody weighed it separately
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '40.000',
            'shortage_quantity' => '5.000', 'warehouse_quantity' => null, 'line_total' => '1050.00',
        ]);

        // Act
        $data = $this->board();

        // Assert — what was never delivered was never sold, and must not be weighed
        $this->assertSame('35.000', $data['weight_comparison']['plain_kg']);
    }

    public function test_plain_bags_are_absent_from_the_printed_piece_count(): void
    {
        // Arrange — a plain line that happens to be sold by the piece
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '700.000',
            'warehouse_quantity' => '14.000', 'line_total' => '800.00',
        ]);

        // Act
        $data = $this->board();

        // Assert
        $this->assertSame(0, $data['printed_pieces']['count']);
        $this->assertSame('800.00', $data['sales_value']['plain']);
    }

    public function test_a_cancelled_order_is_not_on_the_board(): void
    {
        // Arrange
        $cancelled = Order::factory()->status(OrderStatus::Cancelled)->create([
            'cancelled_at' => '2026-03-15 10:00:00', 'delivered_at' => null,
        ]);
        $this->line($cancelled, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '900.000',
            'warehouse_quantity' => '18.000', 'line_total' => '999.00',
        ]);

        // Act
        $data = $this->board();

        // Assert
        $this->assertSame('0.00', $data['sales_value']['total']);
        $this->assertSame(0, $data['orders_counted']);
    }

    public function test_an_order_outside_the_period_is_not_on_the_board(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Delivered)->create([
            'delivered_at' => '2026-02-28 23:00:00',
        ]);
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '100.000', 'line_total' => '110.00',
        ]);

        // Act
        $data = $this->board();

        // Assert
        $this->assertSame('0.00', $data['sales_value']['total']);
    }

    public function test_outsourced_work_is_left_off_the_board_entirely(): void
    {
        // Arrange — ستيكرات beside a bag, on one delivered order
        $order = $this->deliveredOrder();
        $this->line($order, $this->category(ProductionMode::Outsourced), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '200.000', 'line_total' => '500.00',
        ]);
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '300.000',
            'warehouse_quantity' => '6.000', 'line_total' => '330.00',
        ]);

        // Act
        $data = $this->board();

        // Assert — وسيط is neither its own bucket nor folded into سادة; it is simply not a bag
        $this->assertSame('330.00', $data['sales_value']['total']);
        $this->assertSame('0.00', $data['sales_value']['plain']);
        $this->assertCount(1, $data['by_type']);
    }

    public function test_lines_are_classified_individually_inside_one_mixed_order(): void
    {
        // Arrange — the case an order-level answer gets wrong: one printed line among plain ones
        $order = $this->deliveredOrder();
        $plain = $this->category(ProductionMode::None);
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '300.000',
            'warehouse_quantity' => '6.000', 'line_total' => '330.00',
        ]);
        $this->line($order, $plain, attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '10.000', 'line_total' => '320.00',
        ]);
        $this->line($order, $plain, attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '15.000', 'line_total' => '480.00',
        ]);

        // Assert — the plain lines' money stays plain even though the order took the printing road
        $data = $this->board();
        $this->assertSame('330.00', $data['sales_value']['printed']);
        $this->assertSame('800.00', $data['sales_value']['plain']);
        $this->assertSame('6.000', $data['weight_comparison']['printed_kg']);
        $this->assertSame('25.000', $data['weight_comparison']['plain_kg']);
    }

    public function test_a_category_inherits_its_parents_mode(): void
    {
        // Arrange — «سادة» with a child heading left at the default
        $parent = $this->category(ProductionMode::None);
        $child = ProductCategory::factory()->create([
            'production_mode' => ProductionMode::InHouse,
            'parent_id' => $parent->getKey(),
        ]);
        $this->line($this->deliveredOrder(), $child, attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '12.000', 'line_total' => '400.00',
        ]);

        // Act
        $data = $this->board();

        // Assert — the parent's answer reaches it, exactly as ProductCategory::productionMode() says
        $this->assertSame('400.00', $data['sales_value']['plain']);
        $this->assertSame('0.00', $data['sales_value']['printed']);
    }

    public function test_one_pile_is_one_type_however_many_products_draw_on_it(): void
    {
        // Arrange — «كيس شحن مطبوع» and «كيس شحن سادة»: two catalogue rows, one heap
        $group = StockItemGroup::factory()->create(['name' => 'كيس شحن']);
        $shelf = StockItem::factory()->weighed()->inGroup($group)->create();

        $order = $this->deliveredOrder();
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '1000.000',
            'warehouse_quantity' => '20.000', 'line_total' => '1100.00',
        ], shelf: $shelf);
        $this->line($order, $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '30.000', 'line_total' => '960.00',
        ], shelf: $shelf);

        // Act
        $data = $this->board();

        // Assert — one row, carrying its own split
        $this->assertCount(1, $data['by_type']);
        $this->assertSame('كيس شحن', $data['by_type'][0]['type']);
        $this->assertSame('50.000', $data['by_type'][0]['weight_kg']);
        $this->assertSame('20.000', $data['by_type'][0]['printed_kg']);
        $this->assertSame('30.000', $data['by_type'][0]['plain_kg']);
        $this->assertSame('2060.00', $data['by_type'][0]['value']);
        $this->assertSame(1000, $data['by_type'][0]['pieces']);
    }

    public function test_the_type_rows_add_up_to_the_totals_above_them(): void
    {
        // Arrange — two materials, both kinds of goods
        $order = $this->deliveredOrder();
        foreach ([['كيس شحن', '20.000', '1100.00'], ['كيس يد خارجية', '35.000', '1500.00']] as [$name, $kg, $value]) {
            $shelf = StockItem::factory()->weighed()
                ->inGroup(StockItemGroup::factory()->create(['name' => $name]))->create();
            $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
                'pricing_unit' => PricingUnit::Piece, 'quantity' => '1000.000',
                'warehouse_quantity' => $kg, 'line_total' => $value,
            ], shelf: $shelf);
        }

        // Act
        $data = $this->board();

        // Assert — the property the whole board is built to guarantee
        $rowValue = array_sum(array_map(fn (array $r): float => (float) $r['value'], $data['by_type']));
        $rowWeight = array_sum(array_map(fn (array $r): float => (float) $r['weight_kg'], $data['by_type']));
        $this->assertSame((float) $data['sales_value']['total'], $rowValue);
        $this->assertSame((float) $data['weight_comparison']['total_kg'], $rowWeight);
        // Heaviest first
        $this->assertSame('كيس يد خارجية', $data['by_type'][0]['type']);
    }

    public function test_a_type_splits_its_dinars_into_plain_and_printed(): void
    {
        // Arrange — the printed and plain twins of one shipping bag
        $shelf = StockItem::factory()->weighed()->inGroup(StockItemGroup::factory()->create(['name' => 'كيس شحن']))->create();
        $order = $this->deliveredOrder();
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '1000.000',
            'warehouse_quantity' => '20.000', 'line_total' => '1100.00',
        ], shelf: $shelf);
        $this->line($order, $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '30.000', 'line_total' => '960.00',
        ], shelf: $shelf);

        // Act
        $type = $this->board()['by_type'][0];

        // Assert
        $this->assertSame('2060.00', $type['value']);
        $this->assertSame('1100.00', $type['printed_value']);
        $this->assertSame('960.00', $type['plain_value']);
        $this->assertTrue($type['weighed']);
    }

    public function test_plain_and_printed_twins_of_one_size_share_a_size_row(): void
    {
        // Arrange — two sizes of one material; the small one sold both plain and printed
        $group = StockItemGroup::factory()->create(['name' => 'كيس شحن']);
        $small = StockItem::factory()->weighed()->inGroup($group)->size(25, 35)->create();
        $medium = StockItem::factory()->weighed()->inGroup($group)->size(35, 40)->create();

        $order = $this->deliveredOrder();
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '1000.000',
            'warehouse_quantity' => '12.000', 'line_total' => '900.00',
        ], shelf: $small);
        $this->line($order, $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '20.000', 'line_total' => '640.00',
        ], shelf: $small);
        $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '500.000',
            'warehouse_quantity' => '9.000', 'line_total' => '600.00',
        ], shelf: $medium);

        // Act
        $type = $this->board()['by_type'][0];

        // Assert — one row per size, best-selling first
        $this->assertCount(2, $type['sizes']);
        [$first, $second] = $type['sizes'];

        $this->assertSame([25, 35], [$first['width_cm'], $first['height_cm']]);
        $this->assertSame('1540.00', $first['value']);
        $this->assertSame('900.00', $first['printed_value']);
        $this->assertSame('640.00', $first['plain_value']);
        $this->assertSame('12.000', $first['printed_kg']);
        $this->assertSame('20.000', $first['plain_kg']);
        $this->assertSame('32.000', $first['weight_kg']);
        $this->assertSame(1000, $first['pieces']);

        // A size with no plain sales has no plain weight, not a zero one
        $this->assertSame([35, 40], [$second['width_cm'], $second['height_cm']]);
        $this->assertNull($second['plain_kg']);
        $this->assertSame('0.00', $second['plain_value']);

        // The sizes add up to their type
        $this->assertSame($type['value'], number_format(
            array_sum(array_map(fn (array $s): float => (float) $s['value'], $type['sizes'])), 2, '.', '',
        ));
        $this->assertSame($type['weight_kg'], number_format(
            array_sum(array_map(fn (array $s): float => (float) $s['weight_kg'], $type['sizes'])), 3, '.', '',
        ));
    }

    public function test_a_size_nobody_weighed_reports_no_weight_rather_than_zero(): void
    {
        // Arrange — a paper bag, its shelf counted by the piece
        $shelf = StockItem::factory()->unit(PricingUnit::Piece)->size(22, 26)->create();
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '250.000',
            'warehouse_quantity' => null, 'line_total' => '622.50',
        ], shelf: $shelf);

        // Act
        $type = $this->board()['by_type'][0];

        // Assert
        $this->assertFalse($type['weighed']);
        $size = $type['sizes'][0];
        $this->assertNull($size['weight_kg']);
        $this->assertNull($size['printed_kg']);
        $this->assertNull($size['plain_kg']);
        $this->assertSame(250, $size['pieces']);
        $this->assertSame('622.50', $size['value']);
    }

    public function test_plain_sizes_carry_no_piece_count(): void
    {
        // Arrange — plain bags are sold by the kilo and never counted
        $shelf = StockItem::factory()->weighed()->size(45, 50)->create();
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::None), attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '65.000', 'line_total' => '2080.00',
        ], shelf: $shelf);

        // Act
        $size = $this->board()['by_type'][0]['sizes'][0];

        // Assert
        $this->assertNull($size['pieces']);
        $this->assertSame('65.000', $size['plain_kg']);
    }

    public function test_a_line_with_no_size_lands_on_a_last_row_of_its_own(): void
    {
        // Arrange — a made-to-order bag: no shelf, no dimensions, beside a sized one of the same name
        $order = $this->deliveredOrder();
        $category = $this->category(ProductionMode::InHouse);
        $product = Product::factory()->create(['product_category_id' => $category->getKey(), 'name' => 'كيس ورقي 3D']);
        $variant = ProductVariant::factory()->create([
            'product_id' => $product->getKey(), 'stock_item_id' => null,
            'label' => 'حسب الطلب', 'width_cm' => null, 'height_cm' => null,
        ]);
        OrderItem::factory()->for($order)->create([
            'product_id' => $product->getKey(), 'product_variant_id' => $variant->getKey(),
            'product_name' => 'كيس ورقي 3D', 'pricing_unit' => PricingUnit::Piece,
            'quantity' => '100.000', 'warehouse_quantity' => null, 'line_total' => '5000.00',
        ]);

        // Act
        $type = $this->board()['by_type'][0];

        // Assert — its own row, with no dimensions, still counted in the type
        $this->assertSame('كيس ورقي 3D', $type['type']);
        $this->assertCount(1, $type['sizes']);
        $this->assertNull($type['sizes'][0]['width_cm']);
        $this->assertNull($type['sizes'][0]['height_cm']);
        $this->assertSame('5000.00', $type['sizes'][0]['value']);
    }

    public function test_the_unsized_row_comes_after_every_sized_one_whatever_it_sold(): void
    {
        // Arrange — one material, a big unsized sale and a small sized one
        $group = StockItemGroup::factory()->create(['name' => 'كيس ورقي']);
        $sized = StockItem::factory()->unit(PricingUnit::Piece)->inGroup($group)->size(26, 32)->create();
        $unsized = StockItem::factory()->unit(PricingUnit::Piece)->inGroup($group)->unsized()->create();
        $order = $this->deliveredOrder();
        $category = $this->category(ProductionMode::InHouse);

        $product = Product::factory()->create(['product_category_id' => $category->getKey()]);
        $variant = ProductVariant::factory()->create([
            'product_id' => $product->getKey(), 'stock_item_id' => $unsized->getKey(),
            'width_cm' => null, 'height_cm' => null,
        ]);
        OrderItem::factory()->for($order)->create([
            'product_id' => $product->getKey(), 'product_variant_id' => $variant->getKey(),
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '100.000', 'line_total' => '9000.00',
        ]);
        $this->line($order, $category, attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '100.000', 'line_total' => '300.00',
        ], shelf: $sized);

        // Act
        $sizes = $this->board()['by_type'][0]['sizes'];

        // Assert
        $this->assertSame(26, $sizes[0]['width_cm']);
        $this->assertNull($sizes[1]['width_cm']);
    }

    public function test_a_trailing_dash_on_a_shelf_name_is_dropped_and_rows_merge(): void
    {
        // Arrange — two sizes of clear bags, one shelf saved as «أكياس شفافه -», one without the dash
        $order = $this->deliveredOrder();
        $category = $this->category(ProductionMode::None);
        $this->line($order, $category, attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '10.000', 'line_total' => '490.00',
        ], shelf: StockItem::factory()->weighed()->named('أكياس شفافه -')->size(27, 35)->create());
        $this->line($order, $category, attributes: [
            'pricing_unit' => PricingUnit::Kilogram, 'quantity' => '10.000', 'line_total' => '490.00',
        ], shelf: StockItem::factory()->weighed()->named('أكياس شفافه')->size(35, 40)->create());

        // Act
        $data = $this->board();

        // Assert
        $this->assertCount(1, $data['by_type']);
        $this->assertSame('أكياس شفافه', $data['by_type'][0]['type']);
        $this->assertCount(2, $data['by_type'][0]['sizes']);
        $this->assertSame('أكياس شفافه', $data['top_items'][0]['type']);
    }

    public function test_the_best_sellers_are_the_top_five_variants_by_value(): void
    {
        // Arrange — six variants; the cheapest must fall off the list
        $order = $this->deliveredOrder();
        foreach (['100.00', '700.00', '300.00', '600.00', '200.00', '500.00'] as $value) {
            $this->line($order, $this->category(ProductionMode::InHouse), attributes: [
                'pricing_unit' => PricingUnit::Piece, 'quantity' => '100.000',
                'warehouse_quantity' => '1.500', 'line_total' => $value,
            ]);
        }

        // Act
        $top = $this->board()['top_items'];

        // Assert
        $this->assertCount(5, $top);
        $this->assertSame(['700.00', '600.00', '500.00', '300.00', '200.00'], array_column($top, 'value'));
        // 700 of 2400
        $this->assertSame('29.1', $top[0]['share_percent']);
        $this->assertSame('printed', $top[0]['kind']);
        $this->assertSame(100, $top[0]['pieces']);
        $this->assertSame('1.500', $top[0]['weight_kg']);
    }

    public function test_a_best_selling_variant_sums_every_order_it_was_on(): void
    {
        // Arrange — one plain variant on two orders, against a printed one that beats each alone
        $shelf = StockItem::factory()->weighed()->size(45, 50)->create();
        $plain = Product::factory()->create([
            'product_category_id' => $this->category(ProductionMode::None)->getKey(),
            'name' => 'أكياس شحن - سادة',
        ]);
        $variant = ProductVariant::factory()->drawingFrom($shelf)->create([
            'product_id' => $plain->getKey(), 'label' => 'كبير',
        ]);
        foreach (['30.000', '35.000'] as $kg) {
            OrderItem::factory()->for($this->deliveredOrder())->create([
                'product_id' => $plain->getKey(), 'product_variant_id' => $variant->getKey(),
                'pricing_unit' => PricingUnit::Kilogram, 'quantity' => $kg,
                'warehouse_quantity' => null, 'line_total' => '1000.00',
            ]);
        }
        $this->line($this->deliveredOrder(), $this->category(ProductionMode::InHouse), attributes: [
            'pricing_unit' => PricingUnit::Piece, 'quantity' => '1000.000',
            'warehouse_quantity' => '12.000', 'line_total' => '1500.00',
        ]);

        // Act
        $top = $this->board()['top_items'][0];

        // Assert — plain: a weight, no piece count
        $this->assertSame('أكياس شحن - سادة', $top['product']);
        $this->assertSame('كبير', $top['variant']);
        $this->assertSame('plain', $top['kind']);
        $this->assertSame([45, 50], [$top['width_cm'], $top['height_cm']]);
        $this->assertSame('2000.00', $top['value']);
        $this->assertSame('65.000', $top['weight_kg']);
        $this->assertNull($top['pieces']);
    }

    public function test_a_period_with_nothing_in_it_reports_zeroes_rather_than_failing(): void
    {
        // Act
        $response = $this->withHeaders($this->viewer())->getJson(self::ENDPOINT.self::PERIOD);

        // Assert — an empty month is a real month, and a division by zero is not an answer
        $response->assertOk();
        $data = $response->json('data');
        $this->assertSame('0.00', $data['sales_value']['total']);
        $this->assertSame('0.000', $data['weight_comparison']['total_kg']);
        $this->assertSame('0.0', $data['weight_comparison']['printed_share_percent']);
        $this->assertSame('0.0', $data['weight_comparison']['weight_coverage_percent']);
        $this->assertSame(0, $data['printed_pieces']['count']);
        $this->assertSame([], $data['by_type']);
        $this->assertSame([], $data['top_items']);
    }
}
