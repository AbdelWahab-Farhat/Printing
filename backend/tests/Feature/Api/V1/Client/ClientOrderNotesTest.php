<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderStatusTransition;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Activitylog\Models\Activity;
use Tests\TestCase;

/**
 * ملاحظات الطلبية كما يقرؤها العميل: «الملاحظات» تحت بطاقة الحالة، بشارةٍ تعدّ ما لم يُقرأ
 * (طلب المستخدم، 2026-09-25).
 *
 * **لا يرى العميل إلا ما كُتب عند «بانتظار المراجعة» و«رُفض الطلب».** كل ملاحظةٍ أخرى — «ناقص ٤٠
 * كيس» عند «نواقص»، أو ما كُتب عند القبول — كلامُ الورشة لنفسها، ويبقى في تطبيق الموظفين.
 *
 * Arrange - Act - Assert throughout.
 */
class ClientOrderNotesTest extends TestCase
{
    use RefreshDatabase;

    private function customer(string $phone = '0911111111'): Customer
    {
        return Customer::factory()->registered()->create(['phone' => $phone]);
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    private function move(Order $order, ?OrderStatus $from, OrderStatus $to, ?string $reason): OrderStatusTransition
    {
        return OrderStatusTransition::factory()->create([
            'order_id' => $order->id,
            'from_status' => $from,
            'to_status' => $to,
            'reason' => $reason,
        ]);
    }

    public function test_the_notes_are_what_was_written_at_review_and_at_refusal_oldest_first(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::New]);
        $this->move($order, OrderStatus::Requested, OrderStatus::RequestRejected, 'التصميم غير واضح');
        $this->move($order, OrderStatus::RequestRejected, OrderStatus::Requested, 'وصل التصميم الجديد');
        $this->move($order, OrderStatus::Requested, OrderStatus::New, 'قبلناها بعد الاتصال');
        $this->move($order, OrderStatus::New, OrderStatus::Shortage, 'ناقص ٤٠ كيس');

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson("/api/v1/client/orders/{$order->id}/notes");

        // Assert
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.text', 'التصميم غير واضح')
            ->assertJsonPath('data.0.stage', 'rejected')
            ->assertJsonPath('data.0.stage_label', 'مرفوضة')
            ->assertJsonPath('data.1.text', 'وصل التصميم الجديد')
            ->assertJsonPath('data.1.stage', 'under_review')
            ->assertJsonPath('data.1.stage_label', 'بانتظار المراجعة')
            ->assertJsonStructure(['data' => [['id', 'stage', 'stage_label', 'text', 'written_at']]]);
    }

    public function test_a_move_with_no_words_is_not_a_note(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Requested]);
        $this->move($order, null, OrderStatus::Requested, null);
        $this->move($order, OrderStatus::Requested, OrderStatus::RequestRejected, '   ');

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson("/api/v1/client/orders/{$order->id}/notes");

        // Assert
        $response->assertOk()->assertJsonCount(0, 'data');
    }

    /**
     * كرسائل الدعم: الموظف لا يُسمّى للعميل. من كتب الملاحظة هو المتجر.
     */
    public function test_a_note_never_says_which_member_of_staff_wrote_it(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::RequestRejected]);
        $note = $this->move($order, OrderStatus::Requested, OrderStatus::RequestRejected, 'المقاس غير متوفر');
        $note->user()->associate(User::factory()->create(['name' => 'أحمد المراجع']))->save();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson("/api/v1/client/orders/{$order->id}/notes");

        // Assert
        $response->assertOk()
            ->assertDontSee('أحمد المراجع')
            ->assertJsonMissingPath('data.0.user')
            ->assertJsonMissingPath('data.0.user_id');
    }

    public function test_an_opened_order_counts_the_notes_not_yet_read(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Requested]);
        $this->move($order, OrderStatus::Requested, OrderStatus::RequestRejected, 'التصميم غير واضح');
        $this->move($order, OrderStatus::RequestRejected, OrderStatus::Requested, 'وصل التصميم الجديد');
        $this->move($order, OrderStatus::Requested, OrderStatus::New, 'كلامٌ للورشة');

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.unread_notes_count', 2);
    }

    public function test_opening_the_notes_marks_them_read(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::RequestRejected]);
        $this->move($order, OrderStatus::Requested, OrderStatus::RequestRejected, 'التصميم غير واضح');
        $headers = $this->bearerFor($me);

        // Act
        $this->withHeaders($headers)->getJson("/api/v1/client/orders/{$order->id}/notes")->assertOk();
        $response = $this->withHeaders($headers)->getJson("/api/v1/client/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.unread_notes_count', 0);
    }

    public function test_a_note_written_after_the_notes_were_read_is_unread(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Requested]);
        $this->move($order, OrderStatus::Requested, OrderStatus::RequestRejected, 'التصميم غير واضح');
        $headers = $this->bearerFor($me);
        $this->withHeaders($headers)->getJson("/api/v1/client/orders/{$order->id}/notes")->assertOk();
        $this->move($order, OrderStatus::RequestRejected, OrderStatus::Requested, 'أُعيدت للمراجعة');

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/client/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.unread_notes_count', 1);
    }

    /**
     * **القراءة ليست تعديلاً للطلبية.** لا سطر في سجلّها، ولا تتحرّك `updated_at` التي ترتّب بها
     * شاشات الموظفين ما تغيّر.
     */
    public function test_reading_the_notes_is_not_an_edit_of_the_order(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::RequestRejected]);
        $this->move($order, OrderStatus::Requested, OrderStatus::RequestRejected, 'التصميم غير واضح');
        $stamp = $order->fresh()->updated_at;
        $logged = Activity::query()->where('subject_type', $order->getMorphClass())->where('subject_id', $order->id)->count();
        $this->travel(5)->minutes();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson("/api/v1/client/orders/{$order->id}/notes");

        // Assert
        $response->assertOk();
        $this->assertEquals($stamp, $order->fresh()->updated_at);
        $this->assertSame(
            $logged,
            Activity::query()->where('subject_type', $order->getMorphClass())->where('subject_id', $order->id)->count(),
        );
    }

    public function test_another_customers_order_notes_are_a_404(): void
    {
        // Arrange
        $me = $this->customer();
        $theirs = Order::factory()->create(['customer_id' => $this->customer('0922222222')->id]);
        $this->move($theirs, OrderStatus::Requested, OrderStatus::RequestRejected, 'سرّ غيري');

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson("/api/v1/client/orders/{$theirs->id}/notes");

        // Assert
        $response->assertNotFound();
        $this->assertStringNotContainsString('سرّ غيري', (string) $response->getContent());
    }

    public function test_the_notes_need_a_customer_token(): void
    {
        // Arrange
        $order = Order::factory()->create(['customer_id' => $this->customer()->id]);

        // Act
        $response = $this->getJson("/api/v1/client/orders/{$order->id}/notes");

        // Assert
        $response->assertUnauthorized();
    }
}
