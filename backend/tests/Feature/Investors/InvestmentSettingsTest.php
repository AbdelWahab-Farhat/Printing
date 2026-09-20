<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Settings\Models\CompanySetting;
use App\Domain\Settings\SettingsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * إعدادات الاستثمار — the three numbers that govern every pool's calendar.
 *
 * **The point of these tests is what the settings cannot do.** They are read forward only: when a
 * period is opened, when a settlement falls due, when capital is offered. Nothing reads them
 * backwards, so a change today decides what happens next and cannot move a figure anybody has
 * already been paid against. That is a property of the design rather than of a guard, and the
 * defaults test below is what would catch it being quietly broken.
 *
 * Arrange - Act - Assert throughout.
 */
class InvestmentSettingsTest extends TestCase
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
    private function admin(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewCompanySettings->value,
            PermissionName::ManageCompanySettings->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    public function test_the_migration_leaves_the_business_on_the_arrangement_it_already_has(): void
    {
        // Arrange, Act — no seeder ran; the migration wrote the row
        $settings = app(SettingsService::class)->current();

        // Assert — «كل شهر» for the close, «كل ٦ أشهر» for the review, three days of grace
        $this->assertSame(1, (int) $settings->profit_period_months);
        $this->assertSame(6, (int) $settings->settlement_period_months);
        $this->assertSame(3, (int) $settings->entry_grace_days);
        // **Zero, and deliberately so.** A migration that silently locked every investor's capital
        // on the day it ran would be a surprise nobody asked for; the term is switched on from the
        // settings screen when the business decides to.
        $this->assertSame(0, (int) $settings->minimum_term_months);
        $this->assertSame('50.00', (string) $settings->investor_profit_share_percent);
    }

    public function test_the_whole_screen_is_saved_at_once(): void
    {
        // Arrange, Act
        $response = $this->withHeaders($this->admin())->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '60',
            'profit_period_months' => 2,
            'settlement_period_months' => 12,
            'entry_grace_days' => 5,
            'minimum_term_months' => 6,
        ]);

        // Assert
        $response->assertOk();

        $settings = CompanySetting::query()->findOrFail(CompanySetting::SINGLETON_ID);
        $this->assertSame('60.00', (string) $settings->investor_profit_share_percent);
        $this->assertSame(2, (int) $settings->profit_period_months);
        $this->assertSame(12, (int) $settings->settlement_period_months);
        $this->assertSame(5, (int) $settings->entry_grace_days);
        $this->assertSame(6, (int) $settings->minimum_term_months);
    }

    public function test_a_partial_payload_is_refused_rather_than_resetting_what_it_omits(): void
    {
        // Arrange — a stale client that has never heard of the calendar
        // Act
        $response = $this->withHeaders($this->admin())->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '60',
        ]);

        // Assert — it fails loudly instead of silently resetting three values to defaults
        $response->assertStatus(422)->assertJsonValidationErrors([
            'profit_period_months',
            'settlement_period_months',
            'entry_grace_days',
            'minimum_term_months',
        ]);
    }

    public function test_a_grace_window_longer_than_the_shortest_month_is_refused(): void
    {
        // Arrange, Act — 29 days of grace could outlast February entirely
        $response = $this->withHeaders($this->admin())->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'profit_period_months' => 1,
            'settlement_period_months' => 6,
            'entry_grace_days' => 29,
            'minimum_term_months' => 0,
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('entry_grace_days');
    }

    public function test_a_strict_boundary_is_a_legal_setting(): void
    {
        // Arrange, Act — zero grace is the behaviour the ownership arithmetic assumes
        $response = $this->withHeaders($this->admin())->putJson('/api/v1/settings', [
            'investor_profit_share_percent' => '50',
            'profit_period_months' => 1,
            'settlement_period_months' => 6,
            'entry_grace_days' => 0,
            'minimum_term_months' => 0,
        ]);

        // Assert
        $response->assertOk();
        $this->assertSame(0, app(SettingsService::class)->entryGraceDays());
    }

    public function test_reading_the_settings_publishes_every_field_the_write_accepts(): void
    {
        // Arrange, Act — a field on one side and not the other is how a client comes to believe
        // it saved something it did not
        $response = $this->withHeaders($this->admin())->getJson('/api/v1/settings');

        // Assert
        $response->assertOk()->assertJsonStructure([
            'data' => [
                'investor_profit_share_percent',
                'profit_period_months',
                'settlement_period_months',
                'entry_grace_days',
                'minimum_term_months',
            ],
        ]);
    }
}
