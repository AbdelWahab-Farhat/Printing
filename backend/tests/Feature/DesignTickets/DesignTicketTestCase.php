<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Customer\Models\Customer;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Testing\File;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * What every design-ticket test needs: the permission catalogue, the two jobs, and a file.
 *
 * **The two roles are built from permissions rather than from the seeded role**, deliberately. A
 * test that asked for «مصمم» would be asserting that `RoleSeeder` is correct, which is a different
 * claim from the one these files make — and the seeder is explicitly "a starting point, not a
 * policy" that the business may reshape. What the endpoints actually charge is grants, so that is
 * what the tests hand out.
 */
abstract class DesignTicketTestCase extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        // Every file in these tests is written to the designs disk. Faked so nothing lands in
        // storage/app/private, and so `assertExists` can be asked about a path.
        Storage::fake('local');
    }

    /**
     * A signed-in user holding exactly these grants, and the user itself.
     *
     * Returns both because half the assertions here are about *who* did something — the race on
     * acceptance, the refusal to review your own work — and a test that only had headers would
     * have to go looking for the row afterwards.
     *
     * A real personal access token rather than `Sanctum::actingAs()`: that produces a
     * `TransientToken` and skips the path the app actually uses (RULES §6).
     *
     * @return array{0: User, 1: array<string, string>}
     */
    protected function actor(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    /**
     * The employee who raises tickets and passes verdicts on them.
     *
     * @return array{0: User, 1: array<string, string>}
     */
    protected function employee(): array
    {
        return $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ManageDesignTickets,
            PermissionName::AssignDesignTickets,
            PermissionName::ReviewDesignTickets,
        );
    }

    /**
     * The designer, with the three grants `RoleSeeder` gives the role — and nothing else.
     *
     * **No `customers.view`, and that absence is load-bearing**: one of these tests asserts that a
     * designer reads the customer's name off the ticket without it.
     *
     * @return array{0: User, 1: array<string, string>}
     */
    protected function designer(): array
    {
        return $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::AcceptDesignTickets,
            PermissionName::SubmitDesignTickets,
        );
    }

    protected function customer(): Customer
    {
        return Customer::factory()->create(['name' => 'متجر إكس']);
    }

    /** A real PNG, so `getMimeType()` sniffs what it actually is. */
    protected function image(string $name = 'logo.png'): File
    {
        return UploadedFile::fake()->image($name, 1200, 1600);
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    protected function payload(Customer $customer, array $overrides = []): array
    {
        return array_merge([
            'customer_id' => $customer->id,
            'title' => 'تصميم كيس شحن — أسود',
            'description' => 'ضع الشعار في المنتصف وأضف رقم الهاتف أسفله.',
        ], $overrides);
    }

    /**
     * A ticket accepted by this designer, with one version waiting on a verdict.
     *
     * Built through the endpoints rather than the factory, because what most of these tests are
     * about is the sequence — a version that exists without the ticket having moved to
     * «بانتظار المراجعة» is a state the domain cannot produce, and asserting against one would
     * prove nothing.
     *
     * @param  array<string, string>  $designerHeaders
     */
    protected function ticketAwaitingReview(
        DesignTicket $ticket,
        array $designerHeaders,
    ): DesignTicket {
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designerHeaders)
            ->assertOk();

        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v1.png')],
            $designerHeaders,
        )->assertCreated();

        return $ticket->refresh();
    }
}
