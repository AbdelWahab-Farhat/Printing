<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Settings\SettingsService;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * المدد الأربع التي يحكم بها الصندوقُ نفسَه.
 *
 * الشريحة ١ب من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}. أربعةُ أرقامٍ يضبطها
 * المالك من شاشةٍ لا من نشرة:
 *
 * | | |
 * | --- | --- |
 * | مدة الفترة | عليها يقع إقفال الأرباح |
 * | نافذة الاكتتاب | أوّلُ الفترة، ولا يُقبَل إيداعٌ خارجها |
 * | مدة التسوية | مراجعةٌ شاملة، دورتُها أطول |
 * | مدة حجز رأس المال | لا يُسحب رأسُ مالٍ قبل انقضائها |
 *
 * **والوعدُ الذي تحمله هذه الشريحة هو أن تغييرها لا يمسّ ما مضى** — وهو الوعد نفسه الذي تقطعه
 * `investor_profit_share_percent` منذ إنشائها: القيمة تُنسَخ على الصفّ الذي تحكمه يوم مولده،
 * ولا تُقرأ من هنا بعدها. التحقّقُ من ذلك يقع في شريحة الفترة، حيث يوجد صفٌّ يُنسَخ عليه.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundSettingsTest extends TestCase
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
     * @return array<string, string>
     */
    private function headersFor(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    public function test_the_fund_answers_with_its_four_durations(): void
    {
        // Arrange — الصفُّ يُنشئه الترحيل لا البذرة، فالقيم موجودةٌ على قاعدةٍ هُوجرت وحدها.
        $headers = $this->headersFor([PermissionName::ViewCompanySettings]);

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/settings');

        // Assert
        $response->assertOk()->assertJsonPath('data.investment_period_months', 1)
            ->assertJsonPath('data.investment_subscription_window_days', 7)
            ->assertJsonPath('data.investment_settlement_months', 6)
            ->assertJsonPath('data.investment_capital_lock_months', 12);
    }

    public function test_the_owner_may_move_all_four_from_the_screen(): void
    {
        // Arrange
        $headers = $this->headersFor([
            PermissionName::ViewCompanySettings,
            PermissionName::ManageCompanySettings,
        ]);

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'investment_period_months' => 2,
            'investment_subscription_window_days' => 3,
            'investment_settlement_months' => 12,
            'investment_capital_lock_months' => 24,
        ]);

        // Assert
        $response->assertOk();
        $this->assertDatabaseHas('company_settings', [
            'id' => 1,
            'investment_period_months' => 2,
            'investment_subscription_window_days' => 3,
            'investment_settlement_months' => 12,
            'investment_capital_lock_months' => 24,
        ]);
    }

    public function test_a_settlement_that_cuts_a_period_in_half_is_refused(): void
    {
        // Arrange — تسويةٌ كلَّ ٤ أشهر فوق فتراتٍ كلَّ ٣ تقطع الثانية في منتصفها، فتُقوَّم بضاعةٌ
        // لم يُغلق حسابُها بعد.
        $headers = $this->headersFor([
            PermissionName::ViewCompanySettings,
            PermissionName::ManageCompanySettings,
        ]);

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'investment_period_months' => 3,
            'investment_subscription_window_days' => 7,
            'investment_settlement_months' => 4,
            'investment_capital_lock_months' => 12,
        ]);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors('investment_settlement_months');
    }

    public function test_a_period_of_no_months_is_refused(): void
    {
        // Arrange
        $headers = $this->headersFor([
            PermissionName::ViewCompanySettings,
            PermissionName::ManageCompanySettings,
        ]);

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'investment_period_months' => 0,
            'investment_subscription_window_days' => 7,
            'investment_settlement_months' => 6,
            'investment_capital_lock_months' => 12,
        ]);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors('investment_period_months');
    }

    public function test_the_database_refuses_a_settlement_that_is_not_a_whole_multiple(): void
    {
        // Arrange — الحارسُ في القاعدة لا في الطلب وحده: لا يُكتب رقمٌ متناقض مهما كان الطريق.
        $this->expectException(QueryException::class);

        // Act
        DB::table('company_settings')->where('id', 1)->update([
            'investment_period_months' => 3,
            'investment_settlement_months' => 4,
        ]);
    }

    public function test_a_subscription_window_can_never_swallow_a_whole_period(): void
    {
        // Arrange — ٢٨ حدٌّ أعلى مطلقٌ لأنه أقصر شهرٍ ممكن؛ نافذةٌ أطول منه تبتلع فترةً شهرية
        // كاملةً فيصير «أولُ الفترة» هو الفترة.
        $this->expectException(QueryException::class);

        // Act
        DB::table('company_settings')->where('id', 1)
            ->update(['investment_subscription_window_days' => 30]);
    }

    public function test_the_default_plain_price_is_read_and_written_from_the_screen(): void
    {
        // Arrange — **الافتراضُ الذي كان على الصفقة صار في الإعدادات.** صفقةُ D1 تحمل سعرَ سادةٍ
        // على صفّها، فكلُّ رفٍّ موّلته بلا سعرٍ خاصّ يسقط عليه. والصندوقُ صفقةٌ واحدةٌ لا تنتهي
        // ولا يجوز أن يحمل رقماً واحداً لكلّ مادةٍ سيشتريها أبداً — فالافتراضُ هنا، يراه من
        // يموّل ويغيّره لكل رفّ.
        $headers = $this->headersFor([
            PermissionName::ViewCompanySettings,
            PermissionName::ManageCompanySettings,
        ]);

        // Act
        $written = $this->withHeaders($headers)->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'default_plain_sale_price' => '32',
        ]);

        // Assert
        $written->assertOk()->assertJsonPath('data.default_plain_sale_price', '32.000');

        $this->withHeaders($headers)->getJson('/api/v1/settings')
            ->assertOk()
            ->assertJsonPath('data.default_plain_sale_price', '32.000');
    }

    public function test_the_column_is_born_carrying_the_price_the_company_works_with(): void
    {
        // Arrange — «تقدر تكتبه مباشرة 32»، وهي نفسُها التي تحملها D1 على صفّها. أسلوبُ الجدول
        // نفسِه: النسبةُ تُولد بـ٥٠ والمددُ بقيمها، كلُّها في ترحيلها.
        $headers = $this->headersFor([PermissionName::ViewCompanySettings]);

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/settings');

        // Assert
        $response->assertOk()->assertJsonPath('data.default_plain_sale_price', '32.000');
    }

    public function test_a_default_plain_price_of_zero_is_refused(): void
    {
        // Arrange — الحدُّ نفسُه الذي يحرس سعرَ الرفّ: `min:0.001`، فلا يصطدم الصفرُ بقيد
        // القاعدة فيخرج 500 بدل رسالةٍ يقرأها إنسان.
        $headers = $this->headersFor([
            PermissionName::ViewCompanySettings,
            PermissionName::ManageCompanySettings,
        ]);

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'default_plain_sale_price' => '0',
        ]);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors('default_plain_sale_price');
    }

    public function test_the_default_plain_price_can_be_taken_back_off(): void
    {
        // Arrange — «بلا افتراض» جوابٌ مشروع: تُترك الحقولُ فارغةً فتمشي البضاعةُ بالتكلفة،
        // وهو ما كان قبل هذا الإعداد.
        $headers = $this->headersFor([
            PermissionName::ViewCompanySettings,
            PermissionName::ManageCompanySettings,
        ]);

        $this->withHeaders($headers)->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'default_plain_sale_price' => '32',
        ])->assertOk();

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'default_plain_sale_price' => null,
        ]);

        // Assert
        $response->assertOk()->assertJsonPath('data.default_plain_sale_price', null);
        $this->assertDatabaseHas('company_settings', [
            'id' => 1,
            'default_plain_sale_price' => null,
        ]);
    }

    public function test_the_fund_standing_carries_the_default_so_the_funding_screen_can_fill_its_boxes(): void
    {
        // Arrange — الشاشةُ تقرأ اللوحةَ قبل أن تُملأ الحقول؛ طلبٌ ثانٍ للإعدادات في اللحظة
        // نفسها رحلةٌ زائدة لرقمٍ واحد.
        $headers = $this->headersFor([
            PermissionName::ViewCompanySettings,
            PermissionName::ManageCompanySettings,
            PermissionName::ViewInvestors,
        ]);

        $this->withHeaders($headers)->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'default_plain_sale_price' => '32',
        ])->assertOk();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()->assertJsonPath('data.default_plain_sale_price', '32.000');
    }

    public function test_the_service_hands_the_durations_to_whoever_opens_a_period(): void
    {
        // Arrange — تُقرأ من الخدمة لا من النموذج، فيبقى بابُ الإعدادات واحداً.
        $service = app(SettingsService::class);

        // Act
        $durations = $service->investmentDurations();

        // Assert
        $this->assertSame(
            [
                'period_months' => 1,
                'subscription_window_days' => 7,
                'settlement_months' => 6,
                'capital_lock_months' => 12,
            ],
            $durations,
        );
    }
}
