<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\InternalTicket\Models\InternalTicketCategory;
use App\Domain\Order\Models\Order;

/**
 * قائمة «الموظفين»: مَن يرى ماذا، و«تذاكري / الكل» للمدير، والفلاتر والبحث والترتيب وغير المقروء.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class InternalTicketListTest extends InternalTicketTestCase
{
    public function test_an_employee_sees_the_tickets_they_opened_or_were_sent_and_nothing_else(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        [$third, $thirdHeaders] = $this->employee();
        $opened = $this->open($mine, $colleague);
        $received = $this->open($theirs, $me);
        $this->open($thirdHeaders, $colleague);

        // Act
        $response = $this->getJson('/api/v1/internal-tickets', $mine);

        // Assert
        $response->assertOk()->assertJsonPath('meta.total', 2);
        $this->assertEqualsCanonicalizing([$opened->id, $received->id], array_column($response->json('data'), 'id'));
    }

    public function test_a_colleague_with_every_support_permission_still_cannot_open_someone_elses_thread(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [$snoop, $snoopHeaders] = $this->employee();
        $snoop->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, PermissionName::cases()));
        $ticket = $this->open($mine, $colleague);

        // Act
        $show = $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $snoopHeaders);
        $all = $this->getJson('/api/v1/internal-tickets?scope=all', $snoopHeaders);

        // Assert
        $show->assertNotFound();
        $all->assertOk()->assertJsonPath('meta.total', 0);
    }

    public function test_an_admin_reads_everything_on_the_all_tab_and_only_theirs_on_mine(): void
    {
        // Arrange
        [$admin, $adminHeaders] = $this->admin();
        [, $a] = $this->employee();
        [$b] = $this->employee();
        $this->open($a, $b);
        $theirs = $this->open($adminHeaders, $b);

        // Act
        $mine = $this->getJson('/api/v1/internal-tickets', $adminHeaders);
        $all = $this->getJson('/api/v1/internal-tickets?scope=all', $adminHeaders);

        // Assert
        $mine->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $theirs->id);
        $all->assertJsonPath('meta.total', 2);
        $this->assertSame($admin->id, $theirs->opened_by);
    }

    public function test_the_status_chip_filters_open_and_closed(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $open = $this->open($mine, $colleague);
        $closed = $this->open($mine, $colleague);
        $this->postJson("/api/v1/internal-tickets/{$closed->id}/close", [], $mine)->assertOk();

        // Act
        $inProgress = $this->getJson('/api/v1/internal-tickets?status=in_progress', $mine);
        $done = $this->getJson('/api/v1/internal-tickets?status=closed', $mine);

        // Assert
        $inProgress->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $open->id);
        $done->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $closed->id);
    }

    public function test_search_matches_the_code_the_title_and_either_persons_name(): void
    {
        // Arrange
        [, $mine] = $this->employee('سالم');
        [$huda] = $this->employee('هدى المحاسبة');
        [$omar] = $this->employee('عمر');
        $byCode = $this->open($mine, $omar, ['title' => 'شيء']);
        $byTitle = $this->open($mine, $omar, ['title' => 'فاتورة المطبعة']);
        $byName = $this->open($mine, $huda, ['title' => 'سؤال']);

        // Act
        $code = $this->getJson('/api/v1/internal-tickets?search='.strtolower($byCode->code), $mine);
        $title = $this->getJson('/api/v1/internal-tickets?search=المطبعة', $mine);
        $name = $this->getJson('/api/v1/internal-tickets?search=المحاسبة', $mine);

        // Assert
        $this->assertContains($byCode->id, array_column($code->json('data'), 'id'));
        $title->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $byTitle->id);
        $name->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $byName->id);
    }

    public function test_filters_by_category_colleague_order_and_customer(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$huda] = $this->employee();
        [$omar] = $this->employee();
        $category = InternalTicketCategory::query()->where('name', 'مخزون')->firstOrFail();
        $customer = Customer::factory()->create();
        $stock = $this->open($mine, $huda, ['category_id' => $category->id]);
        $aboutCustomer = $this->open($mine, $omar, ['customer_id' => $customer->id]);

        // Act
        $byCategory = $this->getJson("/api/v1/internal-tickets?category_id={$category->id}", $mine);
        $byColleague = $this->getJson("/api/v1/internal-tickets?user_id={$omar->id}", $mine);
        $byCustomer = $this->getJson("/api/v1/internal-tickets?customer_id={$customer->id}", $mine);

        // Assert
        $byCategory->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $stock->id);
        $byColleague->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $aboutCustomer->id);
        $byCustomer->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $aboutCustomer->id);
    }

    public function test_newest_activity_first_or_oldest_on_request(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $older = $this->open($mine, $colleague);
        $this->travel(5)->minutes();
        $newer = $this->open($mine, $colleague);
        $this->travel(5)->minutes();
        $this->say($older, $theirs, ['body' => 'رد'])->assertCreated();

        // Act
        $latest = $this->getJson('/api/v1/internal-tickets', $mine);
        $oldest = $this->getJson('/api/v1/internal-tickets?sort=oldest_activity', $mine);

        // Assert
        $this->assertSame([$older->id, $newer->id], array_column($latest->json('data'), 'id'));
        $this->assertSame([$newer->id, $older->id], array_column($oldest->json('data'), 'id'));
    }

    public function test_the_unread_count_and_filter_follow_the_readers_own_cursor(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $waiting = $this->open($mine, $colleague);
        $quiet = $this->open($mine, $colleague);
        $this->say($waiting, $theirs, ['body' => 'وصلت'])->assertCreated();
        $this->say($waiting, $theirs, ['body' => 'في المخزن'])->assertCreated();

        // Act
        $mineList = $this->getJson('/api/v1/internal-tickets', $mine);
        $unreadOnly = $this->getJson('/api/v1/internal-tickets?unread=1', $mine);
        $theirsList = $this->getJson('/api/v1/internal-tickets', $theirs);

        // Assert
        $rows = collect($mineList->json('data'))->keyBy('id');
        $this->assertSame(2, $rows[$waiting->id]['unread_count']);
        $this->assertSame(0, $rows[$quiet->id]['unread_count']);
        $unreadOnly->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $waiting->id);
        // الزميل كتب الاثنتين — لا غير مقروء عنده فيهما — ولم يفتح الثانية.
        $theirRows = collect($theirsList->json('data'))->keyBy('id');
        $this->assertSame(0, $theirRows[$waiting->id]['unread_count']);
        $this->assertSame(1, $theirRows[$quiet->id]['unread_count']);
    }

    public function test_an_absurd_per_page_is_clamped(): void
    {
        // Arrange
        [, $mine] = $this->employee();

        // Act
        $response = $this->getJson('/api/v1/internal-tickets?per_page=100000', $mine);

        // Assert
        $response->assertOk()->assertJsonPath('meta.per_page', 50);
    }

    public function test_the_list_needs_a_token(): void
    {
        // Act
        $response = $this->getJson('/api/v1/internal-tickets');

        // Assert
        $response->assertUnauthorized();
    }

    public function test_a_missing_ticket_is_not_found(): void
    {
        // Arrange
        [, $mine] = $this->employee();

        // Act
        $response = $this->getJson('/api/v1/internal-tickets/999999', $mine);

        // Assert
        $response->assertNotFound()->assertJsonPath('status', false);
    }

    public function test_an_order_page_lists_only_its_tickets(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $order = Order::factory()->create();
        $aboutOrder = $this->open($mine, $colleague, ['order_id' => $order->id]);
        $this->open($mine, $colleague);

        // Act
        $response = $this->getJson("/api/v1/internal-tickets?order_id={$order->id}", $mine);

        // Assert
        $response->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $aboutOrder->id)
            ->assertJsonPath('data.0.order.code', $order->code);
    }
}
