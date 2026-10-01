<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Exceptions\MovementIsImmutable;
use App\Domain\Treasury\Exceptions\OperationIsImmutable;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The hand operations of الحسابات والخزائن — TREASURY-DESIGN §٤, §١٢.
 *
 * Arrange - Act - Assert throughout.
 */
class TreasuryOperationsTest extends TestCase
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
     * @param  list<PermissionName>  $permissions
     * @return array{0: User, 1: array<string, string>}
     */
    private function clerk(array $permissions = [
        PermissionName::ViewTreasury,
        PermissionName::RecordTreasuryOperations,
        PermissionName::AdjustTreasuryBalances,
        PermissionName::ReverseTreasuryOperations,
        PermissionName::ManageTreasury,
    ]): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    private function cashBox(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', 'cash')->where('is_default', true)->firstOrFail();
    }

    private function bank(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', 'bank')->where('is_default', true)->firstOrFail();
    }

    private function nawris(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('system_code', TreasuryAccount::NAWRIS)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function deposit(array $headers, TreasuryAccount $account, string $amount): void
    {
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $account->id,
            'amount' => $amount,
        ], $headers)->assertCreated();
    }

    // ── what the migration leaves behind ────────────────────────────────────────────────

    public function test_every_kind_a_payment_can_fall_back_to_has_a_default_and_nawris_has_its_account(): void
    {
        // Act
        $defaults = TreasuryAccount::query()->where('is_default', true)->pluck('kind')
            ->map(fn (AccountKind $kind) => $kind->value)->sort()->values()->all();

        // Assert
        $this->assertSame(['bank', 'cash', 'wallet'], $defaults);
        $this->assertSame(AccountKind::Custody, $this->nawris()->kind);
        $this->assertSame('0.00', $this->balance($this->cashBox()));
    }

    // ── deposit, withdrawal, expense ────────────────────────────────────────────────────

    public function test_a_deposit_raises_the_balance_by_one_movement(): void
    {
        // Arrange
        [$user, $headers] = $this->clerk();

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $this->cashBox()->id,
            'amount' => '500',
            'notes' => 'إيداع من المالك',
        ], $headers);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.type', 'deposit')
            ->assertJsonPath('data.amount', '500.00')
            ->assertJsonPath('data.recorder.id', $user->id);

        $this->assertSame('500.00', $this->balance($this->cashBox()));
        $this->assertSame(1, TreasuryMovement::query()->count());
    }

    public function test_a_withdrawal_lowers_the_balance_and_needs_a_reason(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '500');

        // Act
        $withoutReason = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal',
            'from_account_id' => $this->cashBox()->id,
            'amount' => '300',
        ], $headers);

        $withReason = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal',
            'from_account_id' => $this->cashBox()->id,
            'amount' => '300',
            'notes' => 'مصاريف المحل',
        ], $headers);

        // Assert
        $withoutReason->assertUnprocessable()->assertJsonValidationErrors('notes');
        $withReason->assertCreated();
        $this->assertSame('200.00', $this->balance($this->cashBox()));
    }

    public function test_money_that_is_not_there_cannot_be_taken_out_by_hand(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '100');

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal',
            'from_account_id' => $this->cashBox()->id,
            'amount' => '100.01',
            'notes' => 'سحب',
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('100.00', $this->balance($this->cashBox()));
    }

    public function test_an_expense_carries_its_category_and_an_advance_names_the_employee(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '1000');
        $rent = ExpenseCategory::query()->where('name', 'إيجار')->firstOrFail();
        $advance = ExpenseCategory::query()->where('code', ExpenseCategory::ADVANCE)->firstOrFail();
        $employee = User::factory()->create();

        // Act
        $rentPaid = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'expense',
            'from_account_id' => $this->cashBox()->id,
            'amount' => '400',
            'category_id' => $rent->id,
        ], $headers);

        $advanceWithoutEmployee = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'expense',
            'from_account_id' => $this->cashBox()->id,
            'amount' => '100',
            'category_id' => $advance->id,
        ], $headers);

        $advanceWithEmployee = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'expense',
            'from_account_id' => $this->cashBox()->id,
            'amount' => '100',
            'category_id' => $advance->id,
            'employee_id' => $employee->id,
        ], $headers);

        // Assert
        $rentPaid->assertCreated()->assertJsonPath('data.category.name', 'إيجار');
        $advanceWithoutEmployee->assertUnprocessable()->assertJsonValidationErrors('employee_id');
        $advanceWithEmployee->assertCreated()->assertJsonPath('data.employee.id', $employee->id);
        $this->assertSame('500.00', $this->balance($this->cashBox()));
    }

    public function test_an_advance_cannot_name_an_employee_who_was_removed(): void
    {
        // Arrange — موظّفٌ حُذف حذفاً ناعماً ما زال صفُّه في الجدول، فـ`exists` وحدها كانت تقبله.
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '1000');
        $advance = ExpenseCategory::query()->where('code', ExpenseCategory::ADVANCE)->firstOrFail();
        $gone = User::factory()->create();
        $gone->delete();

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'expense',
            'from_account_id' => $this->cashBox()->id,
            'amount' => '100',
            'category_id' => $advance->id,
            'employee_id' => $gone->id,
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('employee_id');
        $this->assertSame('1000.00', $this->balance($this->cashBox()));
    }

    // ── transfer ────────────────────────────────────────────────────────────────────────

    public function test_a_transfer_is_one_operation_with_a_minus_and_a_plus(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '1000');

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer',
            'from_account_id' => $this->cashBox()->id,
            'to_account_id' => $this->bank()->id,
            'amount' => '600',
        ], $headers);

        // Assert
        $response->assertCreated();
        $operation = TreasuryOperation::query()->findOrFail($response->json('data.id'));

        $this->assertSame('400.00', $this->balance($this->cashBox()));
        $this->assertSame('600.00', $this->balance($this->bank()));
        $this->assertSame(2, $operation->movements()->count());
        $this->assertSame(
            $this->bank()->id,
            (int) $operation->movements()->where('direction', 'out')->value('counterpart_account_id'),
        );
    }

    public function test_a_transfer_to_the_same_account_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->clerk();

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer',
            'from_account_id' => $this->cashBox()->id,
            'to_account_id' => $this->cashBox()->id,
            'amount' => '1',
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
    }

    public function test_custody_takes_nothing_by_hand_but_its_opening_and_a_count(): void
    {
        // Arrange
        [, $headers] = $this->clerk();

        // Act
        $deposit = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $this->nawris()->id,
            'amount' => '50',
        ], $headers);

        $opening = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'opening',
            'to_account_id' => $this->nawris()->id,
            'amount' => '50',
        ], $headers);

        // Assert
        $deposit->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
        $opening->assertCreated();
        $this->assertSame('50.00', $this->balance($this->nawris()));
    }

    public function test_an_inactive_account_takes_nothing_by_hand(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $closed = TreasuryAccount::factory()->kind(AccountKind::Bank)->inactive()->create();

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $closed->id,
            'amount' => '10',
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
    }

    // ── opening and count ───────────────────────────────────────────────────────────────

    public function test_an_account_has_one_opening_and_nothing_by_hand_before_it(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'opening',
            'to_account_id' => $this->cashBox()->id,
            'amount' => '8450',
            'occurred_at' => now()->subDay()->toIso8601String(),
        ], $headers)->assertCreated();

        // Act
        $second = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'opening',
            'to_account_id' => $this->cashBox()->id,
            'amount' => '1',
        ], $headers);

        $backdated = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $this->cashBox()->id,
            'amount' => '1',
            'occurred_at' => now()->subDays(3)->toIso8601String(),
        ], $headers);

        // Assert
        $second->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
        $backdated->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $this->assertSame('8450.00', $this->balance($this->cashBox()));
    }

    public function test_a_count_writes_the_difference_and_keeps_both_figures(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '10000');

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'adjustment',
            'to_account_id' => $this->cashBox()->id,
            'counted_balance' => '9950',
            'notes' => 'فرق جرد نقدي',
        ], $headers);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.amount', '50.00')
            ->assertJsonPath('data.system_balance', '10000.00')
            ->assertJsonPath('data.counted_balance', '9950.00')
            ->assertJsonPath('data.from_account_id', $this->cashBox()->id)
            ->assertJsonPath('data.to_account_id', null);

        $this->assertSame('9950.00', $this->balance($this->cashBox()));
    }

    public function test_a_count_that_agrees_or_has_no_reason_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '100');

        // Act
        $agrees = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'adjustment',
            'to_account_id' => $this->cashBox()->id,
            'counted_balance' => '100',
            'notes' => 'جرد',
        ], $headers);

        $noReason = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'adjustment',
            'to_account_id' => $this->cashBox()->id,
            'counted_balance' => '90',
        ], $headers);

        // Assert
        $agrees->assertUnprocessable()->assertJsonValidationErrors('counted_balance');
        $noReason->assertUnprocessable()->assertJsonValidationErrors('notes');
    }

    // ── reversing ───────────────────────────────────────────────────────────────────────

    public function test_reversing_an_operation_mirrors_every_movement_once(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '1000');
        $transfer = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer',
            'from_account_id' => $this->cashBox()->id,
            'to_account_id' => $this->bank()->id,
            'amount' => '600',
        ], $headers)->json('data.id');

        // Act
        $first = $this->postJson("/api/v1/treasury/operations/{$transfer}/reverse", ['reason' => 'خطأ'], $headers);
        $second = $this->postJson("/api/v1/treasury/operations/{$transfer}/reverse", ['reason' => 'خطأ'], $headers);

        // Assert
        $first->assertCreated()->assertJsonPath('data.reverses_operation_id', $transfer);
        $second->assertUnprocessable();
        $this->assertSame('1000.00', $this->balance($this->cashBox()));
        $this->assertSame('0.00', $this->balance($this->bank()));
    }

    public function test_undoing_a_deposit_already_spent_leaves_the_account_red_rather_than_refusing(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $deposit = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $this->cashBox()->id,
            'amount' => '100',
        ], $headers)->json('data.id');
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal',
            'from_account_id' => $this->cashBox()->id,
            'amount' => '80',
            'notes' => 'سحب',
        ], $headers)->assertCreated();

        // Act
        $response = $this->postJson("/api/v1/treasury/operations/{$deposit}/reverse", ['reason' => 'إيداع وهمي'], $headers);

        // Assert
        $response->assertCreated();
        $this->assertSame('-80.00', $this->balance($this->cashBox()));
    }

    public function test_an_opening_is_corrected_by_a_count_not_reversed(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $opening = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'opening',
            'to_account_id' => $this->cashBox()->id,
            'amount' => '100',
        ], $headers)->json('data.id');

        // Act
        $response = $this->postJson("/api/v1/treasury/operations/{$opening}/reverse", ['reason' => 'خطأ'], $headers);

        // Assert
        $response->assertUnprocessable();
    }

    public function test_a_movement_cannot_be_edited(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '100');
        $movement = TreasuryMovement::query()->firstOrFail();

        // Assert
        $this->expectException(MovementIsImmutable::class);

        // Act
        $movement->forceFill(['amount' => '1000'])->save();
    }

    public function test_a_movement_cannot_be_deleted_even_softly(): void
    {
        // Arrange — حذفٌ ناعم يُسقط الحركة من كل رصيد كما يُسقطها التعديل، بلا أثرٍ يقول لماذا.
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '100');
        $movement = TreasuryMovement::query()->firstOrFail();

        // Assert
        $this->expectException(MovementIsImmutable::class);

        // Act
        $movement->delete();
    }

    public function test_an_operation_cannot_be_edited(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '100');
        $operation = TreasuryOperation::query()->firstOrFail();

        // Assert
        $this->expectException(OperationIsImmutable::class);

        // Act
        $operation->forceFill(['amount' => '1000'])->save();
    }

    public function test_an_operation_cannot_be_deleted_even_softly(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '100');
        $operation = TreasuryOperation::query()->firstOrFail();

        // Assert
        $this->expectException(OperationIsImmutable::class);

        // Act
        $operation->delete();
    }

    public function test_an_immutable_operation_is_still_undone_by_its_reversal(): void
    {
        // Arrange — العكسُ صفٌّ جديد يشير إلى أصله، فلا يمسّ الأصلَ بشيء.
        [, $headers] = $this->clerk();
        $this->deposit($headers, $this->cashBox(), '100');
        $operation = TreasuryOperation::query()->firstOrFail();

        // Act
        $response = $this->postJson(
            "/api/v1/treasury/operations/{$operation->id}/reverse",
            ['reason' => 'خطأ'],
            $headers,
        );

        // Assert
        $response->assertCreated();
        $this->assertTrue($operation->refresh()->isReversed());
        $this->assertSame('100.00', (string) $operation->amount);
        $this->assertSame('0.00', $this->balance($this->cashBox()));
    }

    // ── who may ─────────────────────────────────────────────────────────────────────────

    public function test_each_operation_asks_for_its_own_grant(): void
    {
        // Arrange
        [, $recorder] = $this->clerk([PermissionName::RecordTreasuryOperations]);

        // Act
        $deposit = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $this->cashBox()->id, 'amount' => '10',
        ], $recorder);
        $opening = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'opening', 'to_account_id' => $this->bank()->id, 'amount' => '10',
        ], $recorder);
        $count = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'adjustment', 'to_account_id' => $this->cashBox()->id, 'counted_balance' => '0', 'notes' => 'x',
        ], $recorder);
        $unsigned = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $this->cashBox()->id, 'amount' => '10',
        ]);

        // Assert
        $deposit->assertCreated();
        $opening->assertForbidden();
        $count->assertForbidden();
        $unsigned->assertUnauthorized();
    }
}
