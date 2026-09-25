<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * تسعير السلة قبل إرسالها — «التكلفة النهائية» كما تعرضها تطبيقات التسوّق.
 *
 * **الاختبار الذي وُجد له هذا الملف هو `test_the_quote_is_exactly_what_the_order_then_costs`.**
 * السلة تعرض رقماً قبل أن توجد الطلبية، والطلبية تُسعَّر بعدها في مكانٍ آخر من الكود — وإن اختلف
 * الرقمان صار ما رآه العميل وعداً لم يَفِ به المتجر. فالتسعير هنا يمرّ بالطريق الذي تمرّ به الطلبية
 * نفسها، وذلك الاختبار يثبت أنهما لم يفترقا.
 *
 * Arrange - Act - Assert throughout.
 */
class ClientBasketQuoteTest extends TestCase
{
    use RefreshDatabase;

    private function customer(): Customer
    {
        return Customer::factory()->registered()->create(['phone' => '0911111111']);
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    /**
     * منتجٌ بمقاسٍ واحد وسعرٍ واحد من أول قطعة.
     */
    private function product(string $unitPrice = '0.500', ?Product $product = null): Product
    {
        $product ??= Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);

        ProductPriceTier::factory()->create([
            'product_variant_id' => $variant->id,
            'min_quantity' => 1,
            'unit_price' => $unitPrice,
        ]);

        return $product->refresh();
    }

    /**
     * @return array<string, mixed>
     */
    private function line(Product $product, string $quantity = '1000'): array
    {
        return [
            'product_id' => $product->id,
            'product_variant_id' => $product->variants()->first()->id,
            'quantity' => $quantity,
        ];
    }

    // ─────────────────────────── السطور ───────────────────────────

    public function test_each_line_is_priced_and_the_goods_are_totalled(): void
    {
        // Arrange
        $me = $this->customer();
        $bags = $this->product('0.500');
        $boxes = $this->product('1.250');

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($bags, '1000'), $this->line($boxes, '200')],
        ]);

        // Assert — ١٠٠٠ × ٠٫٥ و٢٠٠ × ١٫٢٥.
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.lines.0.product_id', $bags->id)
            ->assertJsonPath('data.lines.0.unit_price', '0.500')
            ->assertJsonPath('data.lines.0.line_total', '500.00')
            ->assertJsonPath('data.lines.1.line_total', '250.00')
            ->assertJsonPath('data.items_total', '750.00');
    }

    /**
     * «كجم» أو «قطعة» — العميل يرى بأيّها تُحسب كميته.
     */
    public function test_each_line_names_its_unit(): void
    {
        // Arrange
        $me = $this->customer();
        $bags = $this->product();
        $plain = $this->product('9.000', Product::factory()->perKilogram()->create());

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($bags, '1000'), $this->line($plain, '12.5')],
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.lines.0.unit', 'piece')
            ->assertJsonPath('data.lines.0.unit_label', 'قطعة')
            ->assertJsonPath('data.lines.1.unit', 'kilogram')
            ->assertJsonPath('data.lines.1.unit_label', 'كجم')
            ->assertJsonPath('data.lines.1.line_total', '112.50');
    }

    /**
     * **منتجٌ «حسب الطلب» لا رقم له، ولا للمجموع إذن.** مجموع السطور المسعّرة وحدها رقمٌ أصغر مما
     * سيُطلب من العميل، مكتوبٌ تحت كلمة «الإجمالي» — الخطأ نفسه الذي تتجنّبه صفحة الطلبية.
     */
    public function test_a_line_priced_on_request_leaves_the_total_open(): void
    {
        // Arrange
        $me = $this->customer();
        $bags = $this->product();
        $reinforced = $this->product('1.000', Product::factory()->quoteOnRequest()->create());

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($bags, '1000'), $this->line($reinforced, '300')],
            'city_id' => City::factory()->create()->id,
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.lines.0.line_total', '500.00')
            ->assertJsonPath('data.lines.1.unit_price', null)
            ->assertJsonPath('data.lines.1.line_total', null)
            ->assertJsonPath('data.items_total', null)
            ->assertJsonPath('data.total_with_delivery', null);
    }

    // ─────────────────────────── التوصيل ───────────────────────────

    /**
     * **التوصيل خارج إجمالي الطلبية ويدخل هنا.** رسم المندوب يُدفع له عند الباب لا لنا، فلا يدخل
     * `grand_total` — لكنه مالٌ يدفعه العميل، و«التكلفة النهائية» التي طلبها صاحب العمل تجمعهما.
     */
    public function test_the_destination_adds_its_delivery_price(): void
    {
        // Arrange
        $me = $this->customer();
        $city = City::factory()->create(['delivery_price' => '15.00']);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($this->product('0.500'), '1000')],
            'city_id' => $city->id,
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.items_total', '500.00')
            ->assertJsonPath('data.delivery_price', '15.00')
            ->assertJsonPath('data.total_with_delivery', '515.00');
    }

    public function test_collecting_from_the_office_costs_nothing_to_deliver(): void
    {
        // Arrange
        $me = $this->customer();
        $office = City::factory()->officePickup()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($this->product('0.500'), '1000')],
            'city_id' => $office->id,
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.delivery_price', '0.00')
            ->assertJsonPath('data.total_with_delivery', '500.00');
    }

    /**
     * مدينةٌ لم يُتّفق على سعرها بعد: التوصيل «يُحدَّد عند المراجعة» لا «مجاناً»، والمجموع الكلي
     * مفتوحٌ معه.
     */
    public function test_a_city_with_no_agreed_rate_leaves_delivery_and_the_total_open(): void
    {
        // Arrange
        $me = $this->customer();
        $city = City::factory()->withoutPrice()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($this->product('0.500'), '1000')],
            'city_id' => $city->id,
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.items_total', '500.00')
            ->assertJsonPath('data.delivery_price', null)
            ->assertJsonPath('data.total_with_delivery', null);
    }

    public function test_no_destination_yet_means_no_delivery_yet(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($this->product('0.500'), '1000')],
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.items_total', '500.00')
            ->assertJsonPath('data.delivery_price', null)
            ->assertJsonPath('data.total_with_delivery', null);
    }

    // ─────────────────────────── الوعد ───────────────────────────

    /**
     * **ما عرضته السلة هو ما كلّفته الطلبية**، سطراً سطراً ومجموعاً — بسعرٍ يُقرّب، لأن التقريب هو
     * المكان الذي يفترق فيه حسابان كُتبا مرتين.
     */
    public function test_the_quote_is_exactly_what_the_order_then_costs(): void
    {
        // Arrange — ٠٫٣٣٣ × ١٠١ = ٣٣٫٦٣٣، وسعرٌ لا يُقسم على القرش يكشف أيّ تقريبٍ مختلف.
        $me = $this->customer();
        $headers = $this->bearerFor($me);
        $items = [
            $this->line($this->product('0.333'), '101'),
            $this->line($this->product('1.117'), '333'),
        ];
        $quote = $this->withHeaders($headers)
            ->postJson('/api/v1/client/orders/quote', ['items' => $items])
            ->json('data');

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/client/orders', [
            'items' => $items,
            'city_id' => City::factory()->create()->id,
        ]);

        // Assert
        $response->assertCreated();
        $order = Order::query()->with('items')->sole();
        $this->assertSame($quote['items_total'], (string) $order->items_total);
        $this->assertSame(
            array_column($quote['lines'], 'line_total'),
            $order->items->sortBy('sort_order')->map(fn ($item) => (string) $item->line_total)->values()->all(),
        );
    }

    public function test_quoting_writes_nothing(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($this->product(), '1000')],
        ]);

        // Assert
        $response->assertOk();
        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
    }

    public function test_the_quote_never_mentions_what_the_goods_cost_us(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($this->product(), '1000')],
        ]);

        // Assert
        $this->assertSame(
            ['product_id', 'product_variant_id', 'unit', 'unit_label', 'unit_price', 'line_total'],
            array_keys((array) $response->json('data.lines.0')),
        );
    }

    // ─────────────────────────── الرفض ───────────────────────────

    public function test_a_quote_needs_at_least_one_line(): void
    {
        // Act
        $response = $this->withHeaders($this->bearerFor($this->customer()))
            ->postJson('/api/v1/client/orders/quote', ['items' => []]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('items');
    }

    /**
     * الحدّ الأدنى قاعدة الكتالوج، والطلبية ترفض ما تحته — فالسلة تقوله قبل الإرسال لا بعده.
     */
    public function test_a_quantity_under_the_minimum_is_refused_as_the_order_would_be(): void
    {
        // Arrange — الحدّ الأدنى في المصنع ١٠٠ قطعة.
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($this->product(), '50')],
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('status', false);
    }

    public function test_a_retired_product_cannot_be_quoted(): void
    {
        // Arrange
        $me = $this->customer();
        $retired = $this->product('0.500', Product::factory()->inactive()->create());

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/orders/quote', [
            'items' => [$this->line($retired, '1000')],
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('items.0.product_id');
    }

    public function test_quoting_needs_a_customer_token(): void
    {
        // Act
        $response = $this->postJson('/api/v1/client/orders/quote', ['items' => []]);

        // Assert
        $response->assertUnauthorized();
    }
}
