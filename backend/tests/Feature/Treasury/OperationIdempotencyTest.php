<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Audit\AuditHiddenAttributes;
use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * الضغطةُ المزدوجة لا تكتب المال مرّتين.
 *
 * اتصالٌ انقطع بعد الحفظ يترك الموظّف لا يعرف هل سُجِّل سحبُه، فيضغط ثانية — وكان الخادم يكتب
 * سحباً ثانياً. **`client_token`** رمزٌ يولّده التطبيق قبل الإرسال (UUID)، والرمزُ نفسه يُرجع
 * العمليةَ الأولى بحالة 200 بدل أن يكتب أخرى. على نسق رسائل الدعم (`ticket_messages.client_token`).
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class OperationIdempotencyTest extends TestCase
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
    private function clerk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ViewVendorPayments,
            PermissionName::RecordVendorPayments,
        ]));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()
            ->where('kind', $kind->value)
            ->where('is_default', true)
            ->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    public function test_an_operation_sent_twice_with_one_token_is_recorded_once(): void
    {
        // Arrange
        $headers = $this->clerk();
        $token = (string) Str::uuid();
        $deposit = [
            'type' => 'deposit',
            'to_account_id' => $this->defaultOf(AccountKind::Cash)->id,
            'amount' => '500',
            'client_token' => $token,
        ];

        // Act
        $first = $this->postJson('/api/v1/treasury/operations', $deposit, $headers);
        $again = $this->postJson('/api/v1/treasury/operations', $deposit, $headers);

        // Assert — الثانيةُ تُرجع الأولى بعينها، ولا حركةَ جديدة.
        $first->assertCreated();
        $again->assertOk()->assertJsonPath('data.id', $first->json('data.id'));
        $this->assertSame(1, TreasuryOperation::query()->count());
        $this->assertSame(1, TreasuryMovement::query()->count());
        $this->assertSame('500.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_two_tokens_are_two_operations(): void
    {
        // Arrange
        $headers = $this->clerk();
        $deposit = fn (string $token) => $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $this->defaultOf(AccountKind::Cash)->id,
            'amount' => '500',
            'client_token' => $token,
        ], $headers);

        // Act
        $first = $deposit((string) Str::uuid());
        $second = $deposit((string) Str::uuid());

        // Assert
        $first->assertCreated();
        $second->assertCreated();
        $this->assertSame('1000.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_a_vendor_payment_sent_twice_with_one_token_is_paid_once(): void
    {
        // Arrange
        $headers = $this->clerk();
        $bank = $this->defaultOf(AccountKind::Bank);
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $bank->id, 'amount' => '1000',
        ], $headers)->assertCreated();
        $vendor = Vendor::factory()->create();
        // مستحقٌّ له ما يكفي (لا دفع مقدّم، §٢٠) — فلا يقف في طريق الدفعة إلا ما يختبره هذا الاختبار.
        PurchaseOrder::factory()->create(['vendor_id' => $vendor->id, 'total_amount' => '1000.00']);
        $payment = [
            'amount' => '400',
            'method' => 'bank_transfer',
            'client_token' => (string) Str::uuid(),
        ];

        // Act
        $first = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", $payment, $headers);
        $again = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", $payment, $headers);

        // Assert
        $first->assertCreated();
        $again->assertOk()->assertJsonPath('data.id', $first->json('data.id'));
        $this->assertSame(1, VendorPayment::query()->count());
        $this->assertSame('600.00', $this->balance($bank));
    }

    public function test_a_token_must_be_a_uuid(): void
    {
        // Arrange
        $headers = $this->clerk();
        $vendor = Vendor::factory()->create();

        // Act
        $operation = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $this->defaultOf(AccountKind::Cash)->id,
            'amount' => '10',
            'client_token' => 'ليس-رمزاً',
        ], $headers);
        $payment = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '10', 'method' => 'cash', 'client_token' => 'abc',
        ], $headers);

        // Assert
        $operation->assertUnprocessable()->assertJsonValidationErrors('client_token');
        $payment->assertUnprocessable()->assertJsonValidationErrors('client_token');
        $this->assertSame(0, TreasuryOperation::query()->count());
    }

    public function test_the_token_stays_out_of_the_history_screen(): void
    {
        // Arrange — رمزُ الإرسال أداةُ نقلٍ لا حدث؛ يُكتب في السجلّ ولا يُرسم، كرمز رسائل الدعم.
        $subjects = [AuditSubject::TreasuryOperation, AuditSubject::VendorPayment];

        // Act
        $hidden = array_map(
            fn (AuditSubject $subject) => AuditHiddenAttributes::hides('client_token', $subject),
            $subjects,
        );

        // Assert
        $this->assertSame([true, true], $hidden);
    }
}
