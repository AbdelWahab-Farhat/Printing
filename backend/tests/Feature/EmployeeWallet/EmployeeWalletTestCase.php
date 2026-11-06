<?php

declare(strict_types=1);

namespace Tests\Feature\EmployeeWallet;

use App\Domain\EmployeeWallet\EmployeeWalletService;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

/**
 * ما تشترك فيه اختبارات «محفظة الموظف» — Docs/employees/EMPLOYEE-WALLET-DESIGN.md.
 *
 * **كل طلبٍ يبدأ بنسيان الحارس**: أكثر من موظفٍ يطلب في الاختبار الواحد، والحاوية تُعاد فيه، فيبقى
 * الحارس على أوّل من سأل إن لم يُنسَ.
 */
abstract class EmployeeWalletTestCase extends TestCase
{
    use RefreshDatabase;

    /** @var list<PermissionName> */
    protected const ALL_GRANTS = [
        PermissionName::ViewEmployeeWallets,
        PermissionName::DepositToEmployeeWallets,
        PermissionName::CreditEmployeeWallets,
        PermissionName::WithdrawFromEmployeeWallets,
        PermissionName::AdjustEmployeeWallets,
        PermissionName::ReverseEmployeeWalletEntries,
    ];

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Storage::fake('local');
    }

    // ── من يطلب ──────────────────────────────────────────────────────────────────────────

    /**
     * @param  list<PermissionName>  $permissions
     * @return array<string, string>
     */
    protected function headersFor(User $user, array $permissions = []): array
    {
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @param  list<PermissionName>  $permissions
     * @return array<string, string>
     */
    protected function auth(array $permissions = []): array
    {
        return $this->headersFor(User::factory()->create(), $permissions);
    }

    /**
     * موظفٌ يملك الصلاحيات الست، وهو غيرُ صاحب المحفظة.
     *
     * @return array<string, string>
     */
    protected function manager(): array
    {
        return $this->auth(self::ALL_GRANTS);
    }

    protected function admin(): User
    {
        $user = User::factory()->create();

        Role::findOrCreate(RoleName::Admin->value, 'web');
        $user->syncRoles([RoleName::Admin->value]);

        return $user;
    }

    // ── الطلبات ──────────────────────────────────────────────────────────────────────────

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    protected function send(array $headers, string $path, array $payload = []): TestResponse
    {
        $this->app->get('auth')->forgetGuards();

        return $this->withHeaders($headers)->postJson("/api/v1/{$path}", $payload);
    }

    /**
     * @param  array<string, string>  $headers
     */
    protected function read(array $headers, string $path): TestResponse
    {
        $this->app->get('auth')->forgetGuards();

        return $this->withHeaders($headers)->getJson("/api/v1/{$path}");
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    protected function deposit(array $headers, User $employee, array $payload = []): TestResponse
    {
        return $this->send($headers, "users/{$employee->id}/wallet/deposits", [
            'amount' => '100',
            'method' => 'cash',
            ...$payload,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    protected function credit(array $headers, User $employee, array $payload = []): TestResponse
    {
        return $this->send($headers, "users/{$employee->id}/wallet/credits", [
            'amount' => '2000',
            'category_id' => $this->salaryCategory()->id,
            ...$payload,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    protected function withdraw(array $headers, User $employee, array $payload = []): TestResponse
    {
        return $this->send($headers, "users/{$employee->id}/wallet/withdrawals", [
            'amount' => '50',
            'method' => 'cash',
            ...$payload,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    protected function adjust(array $headers, User $employee, array $payload = []): TestResponse
    {
        return $this->send($headers, "users/{$employee->id}/wallet/adjustments", [
            'direction' => 'credit',
            'amount' => '10',
            'reason' => 'رصيد افتتاحي',
            ...$payload,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     */
    protected function reverse(array $headers, int $entryId, string $reason = 'سُجّلت خطأً'): TestResponse
    {
        return $this->send($headers, "employee-wallet-entries/{$entryId}/reverse", ['reason' => $reason]);
    }

    // ── ما يُقرأ ─────────────────────────────────────────────────────────────────────────

    protected function balance(User $employee): string
    {
        return app(EmployeeWalletService::class)->balanceOf((int) $employee->id);
    }

    protected function accountBalance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    protected function walletsPayable(): TreasuryAccount
    {
        return app(TreasuryService::class)->employeeWalletsPayable();
    }

    protected function defaultCash(): TreasuryAccount
    {
        return $this->defaultOf(AccountKind::Cash);
    }

    protected function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    protected function salaryCategory(): ExpenseCategory
    {
        return ExpenseCategory::query()->where('code', ExpenseCategory::SALARY)->firstOrFail();
    }

    protected function lockUntil(Carbon $day): void
    {
        TreasurySetting::current()->forceFill(['locked_until' => $day])->save();
    }
}
