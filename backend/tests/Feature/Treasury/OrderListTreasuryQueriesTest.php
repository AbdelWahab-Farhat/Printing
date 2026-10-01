<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * قائمةُ الطلبيات تبني حقولَ كل حركةٍ لكل طلبية — ومنها قائمةُ الحسابات التي يُختار منها.
 *
 * كانت تسأل القاعدةَ السؤالَ نفسَه لكل صفّ، فتكبر الاستعلاماتُ مع طول الصفحة. الجوابُ واحدٌ
 * للطلب كلِّه، فيُسأل مرّةً واحدة. انظر `App\Support\RequestMemo`.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderListTreasuryQueriesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    public function test_a_page_of_orders_reads_the_pickable_accounts_once_not_once_per_order(): void
    {
        // Arrange — ست طلبياتٍ في الطريق، لكلٍّ منها «تم الاستلام» بحقل دفعةٍ وحساب
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewOrders,
            PermissionName::MarkOrdersDelivered,
            PermissionName::SettleOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
        ]));
        TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'مصرف علي']);
        Order::factory()->count(6)->create([
            'status' => OrderStatus::OutForDelivery,
            'items_total' => '100.00',
            'delivery_price' => '0.00',
            'grand_total' => '100.00',
        ]);
        $reads = 0;
        DB::listen(function (QueryExecuted $query) use (&$reads): void {
            if (str_contains($query->sql, 'from "treasury_accounts"')) {
                $reads++;
            }
        });

        // Act
        $response = $this->withHeaders(['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken])
            ->getJson('/api/v1/orders');

        // Assert — والحقلُ ما زال في كل صفّ
        $response->assertOk();
        $this->assertLessThanOrEqual(2, $reads);
        $fields = collect($response->json('data'))
            ->flatMap(fn (array $order) => $order['available_transitions'] ?? [])
            ->flatMap(fn (array $transition) => $transition['fields'] ?? [])
            ->where('key', 'payment_account_id');
        $this->assertCount(6, $fields);
    }
}
