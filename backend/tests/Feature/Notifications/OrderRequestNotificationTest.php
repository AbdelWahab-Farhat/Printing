<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Definitions\OrderAwaitsReview;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * طلبيةٌ وصلت من تطبيق العميل، فيُخبَر مَن يراجعها.
 *
 * **كانت صامتةً عمداً** — «طلبٌ لم يُقبل لا يقاطع أحداً» — فكانت لا تُرى إلا برقمٍ على لوحة الرئيسية
 * لمن فتحها. وطلب المستخدم أن تُشغَّل (2026-09-25). والحالة لا تتغيّر حين تولد الطلبية، فلا يسمعها
 * مستمِعُ الحالات أصلاً: الخبرُ حدثٌ خاصٌّ بالولادة يطلقه `RequestOrder`.
 *
 * **والجمهورُ مَن يستطيع قبولها: `orders.manage`**، لا كلُّ مَن يقرأ الطلبيات. هي نفسُ الصلاحية التي
 * يكلّفها القبولُ والرفض.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class OrderRequestNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    public function test_an_order_from_the_app_reaches_whoever_reviews_requests(): void
    {
        // Arrange — مَن يراجع، ومَن يقرأ الطلبيات ولا يقبل واحدة.
        $reviewer = $this->staff(PermissionName::ManageOrders, PermissionName::ViewOrders);
        $this->staff(PermissionName::ViewOrders);

        // Act
        $order = $this->requestFromTheApp();

        // Assert
        $notification = $this->arrivals()->sole();
        $this->assertSame('order', $notification->subject_type);
        $this->assertSame((int) $order->getKey(), $notification->subject_id);
        $this->assertSame([(int) $reviewer->getKey()], $this->recipientsOf($notification));
    }

    public function test_the_sentence_says_which_order_and_whose_and_opens_it(): void
    {
        // Arrange
        $this->staff(PermissionName::ManageOrders);
        $order = $this->requestFromTheApp();

        // Act
        $rendered = app(OrderAwaitsReview::class)->render($this->arrivals()->sole()->payload);

        // Assert
        $this->assertSame('طلبية جديدة من التطبيق — '.$order->code, $rendered->title);
        $this->assertStringContainsString('عبدو', $rendered->body);
        $this->assertSame('/orders/'.$order->getKey(), $rendered->route);
    }

    public function test_putting_a_refused_request_back_rings_no_second_arrival(): void
    {
        // Arrange — رفضٌ ثم تراجعٌ عنه: حركتا المراجِع نفسه على شاشته، لا طلبيةٌ وصلت.
        $headers = $this->bearer($this->staff(PermissionName::ManageOrders, PermissionName::ViewOrders));
        $order = $this->requestFromTheApp();
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::RequestRejected->value,
            'reason' => 'المقاس غير متوفر',
        ])->assertOk();

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Requested->value,
        ])->assertOk();

        // Assert
        $this->assertSame(1, $this->arrivals()->count());
    }

    private function staff(PermissionName ...$permissions): User
    {
        $user = User::factory()->create(['is_active' => true]);
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return $user;
    }

    /**
     * @return array<string, string>
     */
    private function bearer(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * طلبيةٌ يطلبها العميل من التطبيق، كما يطلبها فعلاً: عبر الوجهة.
     */
    private function requestFromTheApp(): Order
    {
        $customer = Customer::factory()->registered()->create(['phone' => '0911111111', 'name' => 'عبدو']);

        $category = ProductCategory::factory()->create();
        $product = Product::factory()->create(['product_category_id' => $category->id]);
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->create([
            'product_variant_id' => $variant->id,
            'min_quantity' => 1,
            'unit_price' => '0.500',
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken])
            ->postJson('/api/v1/client/orders', [
                'city_id' => City::factory()->create()->id,
                'items' => [[
                    'product_id' => $product->id,
                    'product_variant_id' => $variant->id,
                    'quantity' => 1000,
                ]],
            ])->assertCreated();

        return Order::query()->sole();
    }

    /**
     * @return Builder<Notification>
     */
    private function arrivals()
    {
        return Notification::query()->where('type', NotificationType::OrderRequested);
    }

    /**
     * @return list<int>
     */
    private function recipientsOf(Notification $notification): array
    {
        return $notification->recipients()
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }
}
