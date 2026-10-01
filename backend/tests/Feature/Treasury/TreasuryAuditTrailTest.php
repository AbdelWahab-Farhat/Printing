<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * تاريخُ تصنيف المصروف ودفعة المورد — كلٌّ على بابه، `logs.view` كبقيّة السجلّات.
 *
 * كان كلاهما يُكتب في السجلّ ولا بابَ يُقرأ منه: «من غيّر اسم التصنيف؟» و«من سجّل هذه الدفعة؟»
 * سؤالان لا جواب لهما إلا في قاعدة البيانات.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class TreasuryAuditTrailTest extends TestCase
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
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        // الحارسُ يحفظ أوّلَ مستخدمٍ يحلّه في الاختبار؛ والثاني يُقرأ من رأسه هو.
        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * دفعةٌ لمورد من مصرفٍ فيه ما يكفيها، عبر الشاشة نفسها.
     *
     * @return array{0: Vendor, 1: VendorPayment}
     */
    private function paidVendor(): array
    {
        $headers = $this->auth(
            PermissionName::RecordTreasuryOperations,
            PermissionName::RecordVendorPayments,
        );
        $bank = TreasuryAccount::query()
            ->where('kind', AccountKind::Bank->value)
            ->where('is_default', true)
            ->firstOrFail();
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $bank->id, 'amount' => '1000',
        ], $headers)->assertCreated();
        $vendor = Vendor::factory()->create();
        // مستحقٌّ له ما يكفي (لا دفع مقدّم، §٢٠) — فلا يقف في طريق الدفعة إلا ما يختبره هذا الاختبار.
        PurchaseOrder::factory()->create(['vendor_id' => $vendor->id, 'total_amount' => '1000.00']);
        $paymentId = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '300', 'method' => 'bank_transfer', 'client_token' => (string) Str::uuid(),
        ], $headers)->assertCreated()->json('data.id');

        return [$vendor, VendorPayment::query()->findOrFail($paymentId)];
    }

    public function test_both_records_answer_for_their_own_history(): void
    {
        // Arrange
        $models = [ExpenseCategory::class, VendorPayment::class];

        // Act
        $offenders = array_filter(
            $models,
            fn (string $model) => ! is_subclass_of($model, HasAuditTrail::class),
        );

        // Assert
        $this->assertSame([], array_values($offenders));
    }

    public function test_an_expense_category_has_a_history_of_its_own(): void
    {
        // Arrange
        $manager = $this->auth(PermissionName::ManageTreasury);
        $id = $this->postJson('/api/v1/treasury/expense-categories', ['name' => 'صيانة'], $manager)
            ->assertCreated()->json('data.id');
        $this->putJson("/api/v1/treasury/expense-categories/{$id}", [
            'name' => 'صيانة المكائن',
        ], $manager)->assertOk();
        $auditor = $this->auth(PermissionName::ViewActivityLogs);

        // Act
        $response = $this->getJson("/api/v1/treasury/expense-categories/{$id}/logs", $auditor);

        // Assert
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.event', 'updated')
            ->assertJsonPath('data.1.event', 'created')
            ->assertJsonPath('data.0.subject_type', 'treasury_expense_category')
            ->assertJsonPath('data.0.subject_type_label', 'تصنيف مصروف')
            ->assertJsonPath('data.0.changes.old.name', 'صيانة')
            ->assertJsonPath('data.0.changes.attributes.name', 'صيانة المكائن');
    }

    public function test_a_vendor_payment_has_a_history_of_its_own_without_its_token(): void
    {
        // Arrange
        [$vendor, $payment] = $this->paidVendor();
        $auditor = $this->auth(PermissionName::ViewActivityLogs);
        $url = "/api/v1/vendors/{$vendor->id}/payments/{$payment->id}/logs";

        // Act
        $response = $this->getJson($url, $auditor);

        // Assert — رمزُ الإرسال يُكتب في السجلّ ولا يُرسم.
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.event', 'created')
            ->assertJsonPath('data.0.subject_type', 'vendor_payment')
            ->assertJsonPath('data.0.subject_id', $payment->id)
            ->assertJsonPath('data.0.changes.attributes.amount', '300.00')
            ->assertJsonMissingPath('data.0.changes.attributes.client_token');
    }

    public function test_a_payment_is_read_only_under_its_own_vendor(): void
    {
        // Arrange
        [, $payment] = $this->paidVendor();
        $stranger = Vendor::factory()->create();
        $auditor = $this->auth(PermissionName::ViewActivityLogs);
        $url = "/api/v1/vendors/{$stranger->id}/payments/{$payment->id}/logs";

        // Act
        $response = $this->getJson($url, $auditor);

        // Assert
        $response->assertNotFound();
    }

    public function test_reading_either_history_takes_logs_view(): void
    {
        // Arrange — من يدير التصنيفات أو يدفع للموردين لا يقرأ بذلك ما فعله زملاؤه.
        [$vendor, $payment] = $this->paidVendor();
        $category = ExpenseCategory::query()->firstOrFail();
        $manager = $this->auth(
            PermissionName::ManageTreasury,
            PermissionName::ViewVendorPayments,
            PermissionName::RecordVendorPayments,
        );

        $categoryUrl = "/api/v1/treasury/expense-categories/{$category->id}/logs";
        $paymentUrl = "/api/v1/vendors/{$vendor->id}/payments/{$payment->id}/logs";

        // Act
        $categoryLogs = $this->getJson($categoryUrl, $manager);
        $paymentLogs = $this->getJson($paymentUrl, $manager);

        // Assert
        $categoryLogs->assertForbidden();
        $paymentLogs->assertForbidden();
    }
}
