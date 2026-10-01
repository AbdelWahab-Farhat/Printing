<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * كلُّ سطرٍ في سجلّ الحساب يقول إن كان قد عُكس — فيرسمه التطبيق مشطوباً بعد التحديث أيضاً،
 * لا في اللحظة التي عكسه فيها وحدها.
 *
 * Arrange - Act - Assert throughout.
 */
class LedgerLineStateTest extends TestCase
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
    private function owner(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ReverseTreasuryOperations,
        ]));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function cash(): TreasuryAccount
    {
        return TreasuryAccount::query()
            ->where('kind', AccountKind::Cash->value)
            ->where('is_default', true)
            ->firstOrFail();
    }

    public function test_each_line_says_whether_it_was_reversed(): void
    {
        // Arrange — إيداعٌ قائم، وسحبٌ عُكس ومعه سطرُ عكسه
        $headers = $this->owner();
        $cash = $this->cash();
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $cash->id, 'amount' => '50',
        ], $headers)->assertCreated();
        $withdrawal = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal', 'from_account_id' => $cash->id, 'amount' => '20', 'notes' => 'سحب',
        ], $headers)->assertCreated()->json('data.id');
        $this->postJson("/api/v1/treasury/operations/{$withdrawal}/reverse", ['reason' => 'خطأ'], $headers)
            ->assertCreated();

        // Act
        $response = $this->getJson("/api/v1/treasury/accounts/{$cash->id}/movements", $headers);

        // Assert — الأحدث أولاً: عكسُ السحب، السحبُ المعكوس، الإيداع
        $response->assertOk();
        $this->assertSame([false, true, false], $response->json('data.*.is_reversed'));
    }

    public function test_the_page_asks_once_not_once_per_line(): void
    {
        // Arrange — ستُّ حركات
        $headers = $this->owner();
        $cash = $this->cash();
        foreach (range(1, 6) as $i) {
            $this->postJson('/api/v1/treasury/operations', [
                'type' => 'deposit', 'to_account_id' => $cash->id, 'amount' => (string) (10 * $i),
            ], $headers)->assertCreated();
        }
        $this->app['auth']->forgetGuards();
        $mirrorReads = 0;
        DB::listen(function (QueryExecuted $query) use (&$mirrorReads): void {
            if (str_contains($query->sql, '"reverses_movement_id" in')
                || str_contains($query->sql, '"reverses_movement_id" =')) {
                $mirrorReads++;
            }
        });

        // Act
        $response = $this->getJson("/api/v1/treasury/accounts/{$cash->id}/movements", $headers);

        // Assert
        $response->assertOk();
        $this->assertLessThanOrEqual(1, $mirrorReads);
    }
}
