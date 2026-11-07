<?php

declare(strict_types=1);

namespace Tests\Feature\EmployeeServices;

use App\Domain\Identity\AccessService;
use App\Domain\Identity\Enums\EmployeeServiceType;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\EmployeeServicePrice;
use App\Domain\Identity\Models\User;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Role;
use Tests\Feature\DesignTickets\DesignTicketTestCase;

/**
 * «خدمات الموظفين»: سعرٌ مقترح لكل موظف وخدمة — Docs/employees/SERVICE-PAY-DESIGN.md §٢.
 *
 * Arrange - Act - Assert throughout.
 */
class EmployeeServicePriceTest extends DesignTicketTestCase
{
    /**
     * @param  array<string, string>  $headers
     */
    private function setPrice(User $employee, mixed $price, array $headers): TestResponse
    {
        return $this->putJson(
            "/api/v1/users/{$employee->id}/services/design",
            ['suggested_price' => $price],
            $headers,
        );
    }

    /**
     * @return array<string, string>
     */
    private function salaryManager(): array
    {
        return $this->actor(PermissionName::ManageUserSalaries, PermissionName::ViewUsers)[1];
    }

    public function test_a_designer_gets_a_suggested_price(): void
    {
        // Arrange
        [$designer] = $this->designer();

        // Act
        $response = $this->setPrice($designer, '75.5', $this->salaryManager());

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.services.0.service', 'design')
            ->assertJsonPath('data.services.0.label', 'التصميم')
            ->assertJsonPath('data.services.0.suggested_price', '75.50');
        $this->assertSame(
            '75.50',
            app(AccessService::class)->suggestedPrice($designer, EmployeeServiceType::Design),
        );
    }

    public function test_a_second_price_replaces_the_first(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $headers = $this->salaryManager();
        $this->setPrice($designer, '50', $headers)->assertOk();

        // Act
        $response = $this->setPrice($designer, '60', $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.services.0.suggested_price', '60.00');
        $this->assertSame(1, EmployeeServicePrice::query()->count());
    }

    public function test_the_price_can_be_cleared(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $headers = $this->salaryManager();
        $this->setPrice($designer, '50', $headers)->assertOk();

        // Act
        $response = $this->setPrice($designer, null, $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.services.0.suggested_price', null);
        $this->assertNull(app(AccessService::class)->suggestedPrice($designer, EmployeeServiceType::Design));
    }

    public function test_someone_who_is_not_a_designer_is_refused(): void
    {
        // Arrange
        $accountant = User::factory()->create();

        // Act
        $response = $this->setPrice($accountant, '50', $this->salaryManager());

        // Assert
        $response->assertStatus(422);
        $this->assertSame(0, EmployeeServicePrice::query()->count());
    }

    public function test_a_price_below_zero_is_refused(): void
    {
        // Arrange
        [$designer] = $this->designer();

        // Act
        $response = $this->setPrice($designer, '-1', $this->salaryManager());

        // Assert
        $response->assertStatus(422);
    }

    public function test_setting_a_price_needs_the_salary_grant(): void
    {
        // Arrange
        [$designer] = $this->designer();
        [, $headers] = $this->actor(PermissionName::ViewUsers);

        // Act
        $response = $this->setPrice($designer, '50', $headers);

        // Assert
        $response->assertForbidden();
    }

    public function test_an_unknown_service_is_not_found(): void
    {
        // Arrange
        [$designer] = $this->designer();

        // Act
        $response = $this->putJson(
            "/api/v1/users/{$designer->id}/services/photography",
            ['suggested_price' => '50'],
            $this->salaryManager(),
        );

        // Assert
        $response->assertNotFound();
    }

    public function test_a_designer_who_lost_the_grant_reads_null(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $this->setPrice($designer, '50', $this->salaryManager())->assertOk();

        // Act
        $designer->revokePermissionTo(PermissionName::AcceptDesignTickets->value);

        // Assert
        $this->assertNull(app(AccessService::class)->suggestedPrice($designer->refresh(), EmployeeServiceType::Design));
    }

    public function test_the_employee_page_lists_only_the_services_they_can_give(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $accountant = User::factory()->create();
        $headers = $this->salaryManager();

        // Act
        $designerPage = $this->getJson("/api/v1/users/{$designer->id}", $headers);
        $accountantPage = $this->getJson("/api/v1/users/{$accountant->id}", $headers);

        // Assert
        $designerPage->assertOk()
            ->assertJsonCount(1, 'data.services')
            ->assertJsonPath('data.services.0.suggested_price', null);
        $accountantPage->assertOk()->assertJsonCount(0, 'data.services');
    }

    public function test_reading_the_services_does_not_hand_out_the_employees_grants(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $headers = $this->salaryManager();

        // Act
        $page = $this->getJson("/api/v1/users/{$designer->id}", $headers);
        $list = $this->getJson('/api/v1/users', $headers);

        // Assert
        $page->assertOk()->assertJsonMissingPath('data.permissions');
        $list->assertOk();

        foreach ($list->json('data') as $row) {
            $this->assertArrayNotHasKey('permissions', $row);
        }
    }

    public function test_the_designer_list_tells_a_ticket_manager_the_price(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $this->setPrice($designer, '50', $this->salaryManager())->assertOk();
        [, $headers] = $this->actor(PermissionName::ViewUsers, PermissionName::ManageDesignTickets);

        // Act
        $response = $this->getJson(
            '/api/v1/users?permission='.PermissionName::AcceptDesignTickets->value,
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.0.services.0.suggested_price', '50.00');
    }

    public function test_the_price_is_hidden_from_everybody_else(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $this->setPrice($designer, '50', $this->salaryManager())->assertOk();
        [, $headers] = $this->actor(PermissionName::ViewUsers);

        // Act
        $response = $this->getJson("/api/v1/users/{$designer->id}", $headers);

        // Assert
        $response->assertOk()->assertJsonMissingPath('data.services');
    }

    public function test_a_designer_reads_their_own_price(): void
    {
        // Arrange
        [$designer, $headers] = $this->designer();
        $this->setPrice($designer, '50', $this->salaryManager())->assertOk();

        // Act
        $response = $this->getJson('/api/v1/auth/me', $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.services.0.suggested_price', '50.00');
    }

    public function test_saving_the_price_keeps_the_roles_on_the_answer(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $role = Role::findOrCreate('مصمم تجريبي', 'web');
        $designer->assignRole($role);

        // Act
        $response = $this->setPrice($designer, '50', $this->salaryManager());

        // Assert
        $response->assertOk()->assertJsonPath('data.roles.0.name', 'مصمم تجريبي');
    }

    public function test_the_row_keeps_its_own_history(): void
    {
        // Arrange
        [$designer] = $this->designer();
        $headers = $this->salaryManager();
        $this->setPrice($designer, '50', $headers)->assertOk();
        $this->setPrice($designer, '60', $headers)->assertOk();

        // Act
        $response = $this->getJson("/api/v1/users/{$designer->id}/services/design/logs", $headers);

        // Assert
        $response->assertOk()->assertJsonCount(2, 'data');
    }
}
