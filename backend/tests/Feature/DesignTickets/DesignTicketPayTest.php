<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\EmployeeWallet\EmployeeWalletService;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\Identity\AccessService;
use App\Domain\Identity\Enums\EmployeeServiceType;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Testing\TestResponse;

/**
 * «أجر التصميم» على التذكرة، ودخوله المحفظة عند الاعتماد — Docs/employees/SERVICE-PAY-DESIGN.md.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketPayTest extends DesignTicketTestCase
{
    /**
     * من ينشئ التذاكر ويراجعها، ويرى كلَّها — فلا تحجبه عنها التضييقة.
     *
     * @return array{0: User, 1: array<string, string>}
     */
    private function manager(): array
    {
        return $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ManageDesignTickets,
            PermissionName::AssignDesignTickets,
            PermissionName::ReviewDesignTickets,
        );
    }

    private function ticketFor(User $designer, ?string $pay = '50'): DesignTicket
    {
        $ticket = DesignTicket::factory()->assignedTo((int) $designer->id)->create();

        return tap($ticket, fn () => $ticket->forceFill(['designer_pay' => $pay])->save());
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $extra
     */
    private function approve(DesignTicket $ticket, array $headers, array $extra = []): TestResponse
    {
        $version = $ticket->versions()->sole();

        return $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value, ...$extra],
            $headers,
        );
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function setPay(DesignTicket $ticket, mixed $pay, array $headers): TestResponse
    {
        return $this->patchJson("/api/v1/design-tickets/{$ticket->id}/pay", ['designer_pay' => $pay], $headers);
    }

    private function balance(User $employee): string
    {
        return app(EmployeeWalletService::class)->balanceOf((int) $employee->id);
    }

    private function suggest(User $designer, string $price): void
    {
        app(AccessService::class)->setServicePrice($designer, EmployeeServiceType::Design, $price);
    }

    // ── الكتابة ──────────────────────────────────────────────────────────────────────────

    public function test_a_ticket_can_be_raised_with_a_pay(): void
    {
        // Arrange
        [, $headers] = $this->manager();

        // Act
        $response = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($this->customer(), ['designer_pay' => '50']),
            $headers,
        );

        // Assert
        $response->assertCreated()->assertJsonPath('data.designer_pay', '50.00');
        $this->assertSame('50.00', (string) DesignTicket::query()->sole()->designer_pay);
    }

    public function test_the_pay_is_optional_on_a_new_ticket(): void
    {
        // Arrange
        [, $headers] = $this->manager();

        // Act
        $response = $this->postJson('/api/v1/design-tickets', $this->payload($this->customer()), $headers);

        // Assert
        $response->assertCreated()->assertJsonPath('data.designer_pay', null);
    }

    public function test_a_pay_below_zero_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->manager();

        // Act
        $response = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($this->customer(), ['designer_pay' => '-1']),
            $headers,
        );

        // Assert
        $response->assertStatus(422);
    }

    public function test_whoever_raises_tickets_can_change_the_pay(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $ticket = $this->ticketFor($designer);
        [, $headers] = $this->manager();

        // Act
        $response = $this->setPay($ticket, '70', $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.designer_pay', '70.00');
    }

    public function test_the_designer_responsible_can_change_the_pay(): void
    {
        // Arrange
        [$designer, $headers] = $this->designer();
        $ticket = $this->ticketFor($designer);

        // Act
        $response = $this->setPay($ticket, '70', $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.designer_pay', '70.00');
    }

    public function test_the_pay_can_be_cleared(): void
    {
        // Arrange
        [$designer, $headers] = $this->designer();
        $ticket = $this->ticketFor($designer);

        // Act
        $response = $this->setPay($ticket, null, $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.designer_pay', null);
    }

    public function test_another_designer_cannot_change_the_pay(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $ticket = $this->ticketFor($designer);
        [, $headers] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::AcceptDesignTickets,
        );

        // Act
        $response = $this->setPay($ticket, '500', $headers);

        // Assert
        $response->assertForbidden();
        $this->assertSame('50.00', (string) $ticket->refresh()->designer_pay);
    }

    public function test_a_pool_ticket_is_not_written_before_it_is_taken(): void
    {
        // Arrange
        $ticket = DesignTicket::factory()->create();
        [, $headers] = $this->designer();

        // Act
        $response = $this->setPay($ticket, '500', $headers);

        // Assert
        $response->assertForbidden();
        $this->assertNull($ticket->refresh()->designer_pay);
    }

    public function test_a_closed_ticket_keeps_its_pay(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $ticket = DesignTicket::factory()->assignedTo((int) $designer->id)->cancelled()->create();
        [, $headers] = $this->manager();

        // Act
        $response = $this->setPay($ticket, '70', $headers);

        // Assert
        $response->assertStatus(422);
        $this->assertNull($ticket->refresh()->designer_pay);
    }

    public function test_whoever_takes_a_pool_ticket_can_state_the_pay(): void
    {
        // Arrange
        $ticket = DesignTicket::factory()->create();
        [, $headers] = $this->designer();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/acceptance",
            ['designer_pay' => '65'],
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.designer_pay', '65.00');
    }

    public function test_accepting_without_a_pay_leaves_the_pay_alone(): void
    {
        // Arrange
        [$designer, $headers] = $this->designer();
        $ticket = $this->ticketFor($designer);

        // Act
        $response = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.designer_pay', '50.00');
    }

    public function test_the_pay_survives_a_change_of_designer(): void
    {
        // Arrange
        [$first, $firstHeaders] = $this->designer();
        $ticket = $this->ticketFor($first);
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $firstHeaders)->assertOk();
        [, $headers] = $this->manager();

        // Act
        $response = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => null],
            $headers,
        );

        // Assert
        $response->assertOk();
        $this->assertSame('50.00', (string) $ticket->refresh()->designer_pay);
    }

    public function test_a_suggested_price_never_fixes_the_pay_by_itself(): void
    {
        // Arrange
        $ticket = DesignTicket::factory()->create();
        [$designer, $headers] = $this->designer();
        $this->suggest($designer, '75');

        // Act
        $response = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.designer_pay', null);
    }

    // ── من يقرؤه ─────────────────────────────────────────────────────────────────────────

    public function test_the_people_involved_read_the_pay(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketFor($designer);
        [, $manager] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ManageDesignTickets,
        );
        [, $reviewer] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ReviewDesignTickets,
        );

        // Act
        $asDesigner = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $designerHeaders);
        $asManager = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $manager);
        $asReviewer = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $reviewer);

        // Assert
        $asDesigner->assertOk()->assertJsonPath('data.designer_pay', '50.00')->assertJsonPath('data.can_set_pay', true);
        $asManager->assertOk()->assertJsonPath('data.designer_pay', '50.00')->assertJsonPath('data.can_set_pay', true);
        $asReviewer->assertOk()->assertJsonPath('data.designer_pay', '50.00')->assertJsonPath('data.can_set_pay', false);
    }

    public function test_a_designer_looking_at_the_pool_reads_the_pay(): void
    {
        // Arrange
        $ticket = DesignTicket::factory()->create();
        $ticket->forceFill(['designer_pay' => '50'])->save();
        [, $headers] = $this->designer();

        // Act
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.designer_pay', '50.00')
            ->assertJsonPath('data.can_set_pay', false);
    }

    public function test_an_onlooker_never_reads_the_pay(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $ticket = $this->ticketFor($designer);
        [, $headers] = $this->actor(PermissionName::ViewDesignTickets, PermissionName::ViewAllDesignTickets);

        // Act
        $detail = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $headers);
        $list = $this->getJson('/api/v1/design-tickets', $headers);

        // Assert
        $detail->assertOk()
            ->assertJsonMissingPath('data.designer_pay')
            ->assertJsonMissingPath('data.suggested_pay')
            ->assertJsonPath('data.can_set_pay', false);
        $list->assertOk()->assertJsonMissingPath('data.0.designer_pay');
    }

    public function test_the_history_hides_the_pay_from_an_onlooker(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $ticket = $this->ticketFor($designer);
        [, $manager] = $this->manager();
        $this->setPay($ticket, '70', $manager)->assertOk();
        [, $onlooker] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ViewActivityLogs,
        );
        [, $readerOfThePay] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ViewActivityLogs,
            PermissionName::ManageDesignTickets,
        );

        // Act
        $hidden = $this->getJson("/api/v1/design-tickets/{$ticket->id}/logs", $onlooker);
        $shown = $this->getJson("/api/v1/design-tickets/{$ticket->id}/logs", $readerOfThePay);

        // Assert
        $amounts = fn (TestResponse $response): array => collect($response->assertOk()->json('data'))
            ->map(fn (array $entry): mixed => $entry['changes']['attributes']['designer_pay'] ?? null)
            ->filter()
            ->values()
            ->all();

        $this->assertSame([], $amounts($hidden));
        $this->assertContains('70.00', $amounts($shown));
    }

    public function test_the_suggestion_is_the_named_designers(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $this->suggest($designer, '75');
        $ticket = $this->ticketFor($designer, null);
        [, $headers] = $this->manager();

        // Act
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.designer_pay', null)
            ->assertJsonPath('data.suggested_pay', '75.00');
    }

    public function test_on_a_pool_ticket_the_suggestion_is_the_readers_own(): void
    {
        // Arrange
        $ticket = DesignTicket::factory()->create();
        [$designer, $headers] = $this->designer();
        $this->suggest($designer, '75');

        // Act
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.suggested_pay', '75.00');
    }

    // ── الاعتماد ─────────────────────────────────────────────────────────────────────────

    public function test_approval_puts_the_pay_in_the_designers_wallet(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        [$reviewer, $reviewerHeaders] = $this->manager();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders);

        // Assert
        $response->assertOk();
        $this->assertSame(DesignTicketStatus::Completed, $ticket->refresh()->status);
        $this->assertSame('50.00', $this->balance($designer));

        $entry = EmployeeWalletEntry::query()->sole();
        $this->assertSame(EmployeeWalletEntryType::Credit, $entry->type);
        $this->assertSame((int) $designer->id, (int) $entry->user_id);
        $this->assertSame((int) $reviewer->id, (int) $entry->recorded_by);
        $this->assertSame("أجر تصميم {$ticket->code}", $entry->notes);
        $this->assertSame("design-ticket:{$ticket->id}", $entry->client_token);

        $operation = TreasuryOperation::query()->where('type', OperationType::WalletExpense->value)->sole();
        $this->assertSame('50.00', (string) $operation->amount);
        $this->assertSame(ExpenseCategory::DESIGN_PAY, ExpenseCategory::query()->find($operation->category_id)?->code);
        $this->assertSame((int) $designer->id, (int) $operation->employee_id);

        $treasury = app(TreasuryService::class);
        $this->assertSame('-50.00', $treasury->balanceOf($treasury->employeeWalletsPayable()));
        $this->artisan('wallets:check')->assertExitCode(0);
    }

    public function test_the_wallet_row_reads_design_pay(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        [, $reviewerHeaders] = $this->manager();
        $this->approve($ticket, $reviewerHeaders)->assertOk();

        [, $walletReader] = $this->actor(PermissionName::ViewEmployeeWallets);

        // Act
        $own = $this->getJson('/api/v1/my-wallet/entries', $designerHeaders);
        $all = $this->getJson('/api/v1/employee-wallet-entries', $walletReader);

        // Assert
        $own->assertOk()
            ->assertJsonPath('data.0.type', 'credit')
            ->assertJsonPath('data.0.type_label', 'أجر التصميم')
            ->assertJsonPath('data.0.direction', 'in');
        $all->assertOk()->assertJsonPath('data.0.type_label', 'أجر التصميم');
    }

    public function test_a_ticket_without_a_pay_completes_with_no_money(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer, null), $designerHeaders);
        [, $reviewerHeaders] = $this->manager();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders);

        // Assert
        $response->assertOk();
        $this->assertSame(DesignTicketStatus::Completed, $ticket->refresh()->status);
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_a_pay_of_zero_moves_no_money(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer, '0'), $designerHeaders);
        [, $reviewerHeaders] = $this->manager();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders);

        // Assert
        $response->assertOk();
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_a_change_request_moves_no_money(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        [, $reviewerHeaders] = $this->manager();
        $version = $ticket->versions()->sole();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::ChangesRequested->value, 'note' => 'كبّر الشعار'],
            $reviewerHeaders,
        );

        // Assert
        $response->assertOk();
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_a_cancellation_moves_no_money(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        [, $headers] = $this->manager();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/cancellation",
            ['reason' => 'ألغى الزبون الطلب'],
            $headers,
        );

        // Assert
        $response->assertOk();
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_the_money_goes_to_whoever_drew_the_approved_version(): void
    {
        // Arrange
        [$first, $firstHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($first), $firstHeaders);
        [, $reviewerHeaders] = $this->manager();
        $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => null],
            $reviewerHeaders,
        )->assertOk();
        [$second, $secondHeaders] = $this->designer();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $secondHeaders)->assertOk();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders);

        // Assert
        $response->assertOk();
        $this->assertSame('50.00', $this->balance($first));
        $this->assertSame('0.00', $this->balance($second));
    }

    public function test_approval_is_refused_when_the_pay_changed_under_the_dialog(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        $this->setPay($ticket, '500', $designerHeaders)->assertOk();
        [, $reviewerHeaders] = $this->manager();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders, ['confirmed_pay' => '50']);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(DesignTicketStatus::UnderReview, $ticket->refresh()->status);
        $this->assertSame(DesignSubmissionStatus::Proposed, $ticket->versions()->sole()->status);
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_a_pay_added_under_the_dialog_is_refused_too(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer, null), $designerHeaders);
        $this->setPay($ticket, '500', $designerHeaders)->assertOk();
        [, $reviewerHeaders] = $this->manager();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders, ['confirmed_pay' => '0']);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_approval_passes_when_the_confirmed_pay_matches(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        [, $reviewerHeaders] = $this->manager();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders, ['confirmed_pay' => '50.00']);

        // Assert
        $response->assertOk();
        $this->assertSame('50.00', $this->balance($designer));
    }

    public function test_a_treasury_lock_covering_today_does_not_stop_an_approval(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        [, $reviewerHeaders] = $this->manager();
        TreasurySetting::current()->forceFill(['locked_until' => now()->addDay()])->save();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders);

        // Assert
        $response->assertOk();
        $this->assertSame('50.00', $this->balance($designer));
    }

    public function test_a_second_approval_pays_nothing(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        [, $reviewerHeaders] = $this->manager();
        $this->approve($ticket, $reviewerHeaders)->assertOk();

        // Act
        $response = $this->approve($ticket, $reviewerHeaders);

        // Assert
        $response->assertStatus(422);
        $this->assertSame('50.00', $this->balance($designer));
    }

    public function test_the_reviewer_who_drew_it_is_still_refused(): void
    {
        // Arrange
        [$designer, $headers] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::AcceptDesignTickets,
            PermissionName::SubmitDesignTickets,
            PermissionName::ReviewDesignTickets,
        );
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $headers);

        // Act
        $response = $this->approve($ticket, $headers);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_the_pay_can_be_reversed_from_the_wallet(): void
    {
        // Arrange
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->ticketFor($designer), $designerHeaders);
        [, $reviewerHeaders] = $this->manager();
        $this->approve($ticket, $reviewerHeaders)->assertOk();
        $entry = EmployeeWalletEntry::query()->sole();
        [, $walletManager] = $this->actor(PermissionName::ReverseEmployeeWalletEntries);

        // Act
        $response = $this->postJson(
            "/api/v1/employee-wallet-entries/{$entry->id}/reverse",
            ['reason' => 'اعتُمد بالخطأ'],
            $walletManager,
        );

        // Assert
        $response->assertSuccessful();
        $this->assertSame('0.00', $this->balance($designer));
        $this->assertSame(DesignTicketStatus::Completed, $ticket->refresh()->status);
    }

    public function test_the_design_pay_category_can_be_used_by_hand(): void
    {
        // Arrange
        [$designer] = $this->designer();
        [, $headers] = $this->actor(PermissionName::CreditEmployeeWallets);
        $category = ExpenseCategory::query()->where('code', ExpenseCategory::DESIGN_PAY)->firstOrFail();

        // Act
        $response = $this->postJson(
            "/api/v1/users/{$designer->id}/wallet/credits",
            ['amount' => '30', 'category_id' => $category->id],
            $headers,
        );

        // Assert
        $response->assertSuccessful();
        $this->assertSame('30.00', $this->balance($designer));
    }
}
