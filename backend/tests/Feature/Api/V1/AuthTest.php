<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Authenticate with a real personal access token rather than Sanctum::actingAs, so the
     * tests exercise the same Bearer-token path the Flutter app will use.
     *
     * @return array<string, string>
     */
    private function bearerFor(User $user, string $device = 'test-device'): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken($device)->plainTextToken];
    }

    /**
     * Drop the resolved user from the auth guards.
     *
     * The test container is reused across requests inside one test, so a guard that already
     * authenticated somebody keeps returning them even after their token is deleted. A real
     * request boots a fresh container and re-reads the token, so clearing the guards here is
     * what makes the assertion match production behaviour.
     */
    private function forgetAuthenticatedUser(): void
    {
        $this->app->get('auth')->forgetGuards();
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, string>
     */
    private function validRegistrationPayload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'عبدالوهاب فرحات',
            'email' => 'abdelwahab@printing.ly',
            'phone' => '0911234567',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ], $overrides);
    }

    // ───────────────────────────── register ─────────────────────────────

    public function test_register_creates_the_user_and_returns_a_usable_token(): void
    {
        $response = $this->postJson('/api/v1/auth/register', $this->validRegistrationPayload());

        $response->assertCreated()
            ->assertJson([
                'status' => true,
                'message' => 'تم إنشاء الحساب بنجاح',
                'data' => [
                    'user' => [
                        'name' => 'عبدالوهاب فرحات',
                        'email' => 'abdelwahab@printing.ly',
                        'phone' => '0911234567',
                    ],
                ],
            ])
            ->assertJsonStructure([
                'status',
                'message',
                'data' => ['user' => ['id', 'name', 'email', 'phone', 'created_at'], 'token'],
            ]);

        $this->assertDatabaseHas('users', ['email' => 'abdelwahab@printing.ly']);

        // The token handed back must actually authenticate.
        $token = $response->json('data.token');
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/auth/me')
            ->assertOk();
    }

    public function test_register_never_exposes_the_password_hash(): void
    {
        $response = $this->postJson('/api/v1/auth/register', $this->validRegistrationPayload());

        $response->assertCreated();
        $this->assertArrayNotHasKey('password', $response->json('data.user'));
    }

    public function test_register_stores_the_password_hashed(): void
    {
        $this->postJson('/api/v1/auth/register', $this->validRegistrationPayload())->assertCreated();

        $user = User::query()->where('email', 'abdelwahab@printing.ly')->firstOrFail();

        $this->assertNotSame('password123', $user->password);
        $this->assertTrue(Hash::check('password123', $user->password));
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    #[DataProvider('invalidRegistrationCases')]
    public function test_register_rejects_invalid_input(array $overrides, string $invalidField): void
    {
        $response = $this->postJson('/api/v1/auth/register', $this->validRegistrationPayload($overrides));

        $response->assertStatus(422)
            ->assertJson(['status' => false, 'data' => null])
            ->assertJsonValidationErrors($invalidField);
    }

    /**
     * @return array<string, array{array<string, mixed>, string}>
     */
    public static function invalidRegistrationCases(): array
    {
        return [
            'name missing' => [['name' => ''], 'name'],
            'name too short' => [['name' => 'ab'], 'name'],
            'email missing' => [['email' => ''], 'email'],
            'email malformed' => [['email' => 'not-an-email'], 'email'],
            'phone missing' => [['phone' => ''], 'phone'],
            'phone wrong prefix' => [['phone' => '0811234567'], 'phone'],
            'phone too short' => [['phone' => '09123'], 'phone'],
            'phone not numeric' => [['phone' => '09abcdefgh'], 'phone'],
            'password missing' => [['password' => '', 'password_confirmation' => ''], 'password'],
            'password too short' => [['password' => 'short1', 'password_confirmation' => 'short1'], 'password'],
            'password not confirmed' => [['password_confirmation' => 'different123'], 'password'],
        ];
    }

    public function test_register_rejects_a_duplicate_email(): void
    {
        User::factory()->create(['email' => 'taken@printing.ly']);

        $this->postJson('/api/v1/auth/register', $this->validRegistrationPayload(['email' => 'taken@printing.ly']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('email');
    }

    public function test_register_rejects_a_duplicate_phone(): void
    {
        User::factory()->create(['phone' => '0911234567']);

        $this->postJson('/api/v1/auth/register', $this->validRegistrationPayload(['phone' => '0911234567']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('phone');
    }

    public function test_register_validation_errors_are_returned_in_an_errors_object(): void
    {
        $response = $this->postJson('/api/v1/auth/register', []);

        $response->assertStatus(422)
            ->assertJsonStructure(['status', 'message', 'data', 'errors'])
            ->assertJson(['message' => 'البيانات المدخلة غير صحيحة']);
    }

    // ───────────────────────────── login ─────────────────────────────

    public function test_login_with_email_succeeds(): void
    {
        $user = User::factory()->create(['email' => 'user@printing.ly']);

        $this->postJson('/api/v1/auth/login', ['login' => 'user@printing.ly', 'password' => 'password'])
            ->assertOk()
            ->assertJson([
                'status' => true,
                'message' => 'تم تسجيل الدخول بنجاح',
                'data' => ['user' => ['id' => $user->id]],
            ])
            ->assertJsonStructure(['data' => ['user' => ['id', 'name', 'email', 'phone'], 'token']]);
    }

    public function test_login_with_phone_succeeds(): void
    {
        $user = User::factory()->create(['phone' => '0917654321']);

        $this->postJson('/api/v1/auth/login', ['login' => '0917654321', 'password' => 'password'])
            ->assertOk()
            ->assertJson(['status' => true, 'data' => ['user' => ['id' => $user->id]]]);
    }

    public function test_login_rejects_a_wrong_password(): void
    {
        User::factory()->create(['email' => 'user@printing.ly']);

        $this->postJson('/api/v1/auth/login', ['login' => 'user@printing.ly', 'password' => 'wrong-password'])
            ->assertStatus(422)
            ->assertJson(['status' => false])
            ->assertJsonValidationErrors('login');
    }

    public function test_login_gives_the_same_error_for_an_unknown_account_as_for_a_wrong_password(): void
    {
        User::factory()->create(['email' => 'user@printing.ly']);

        $wrongPassword = $this->postJson('/api/v1/auth/login', [
            'login' => 'user@printing.ly', 'password' => 'wrong-password',
        ]);

        $unknownUser = $this->postJson('/api/v1/auth/login', [
            'login' => 'nobody@printing.ly', 'password' => 'wrong-password',
        ]);

        // Identical responses, otherwise the endpoint reveals which accounts exist.
        $unknownUser->assertStatus(422);
        $this->assertSame(
            $wrongPassword->json('errors.login'),
            $unknownUser->json('errors.login'),
        );
    }

    public function test_login_requires_both_fields(): void
    {
        $this->postJson('/api/v1/auth/login', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['login', 'password']);
    }

    public function test_login_names_the_token_after_the_device_when_one_is_given(): void
    {
        $user = User::factory()->create(['email' => 'user@printing.ly']);

        $this->postJson('/api/v1/auth/login', [
            'login' => 'user@printing.ly',
            'password' => 'password',
            'device_name' => 'iPhone 15',
        ])->assertOk();

        $this->assertDatabaseHas('personal_access_tokens', [
            'tokenable_id' => $user->id,
            'name' => 'iPhone 15',
        ]);
    }

    // ───────────────────────────── me ─────────────────────────────

    public function test_me_returns_the_authenticated_user(): void
    {
        $user = User::factory()->create();

        $this->withHeaders($this->bearerFor($user))
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJson([
                'status' => true,
                'data' => ['id' => $user->id, 'email' => $user->email, 'phone' => $user->phone],
            ]);
    }

    public function test_me_rejects_an_unauthenticated_request_with_a_json_401(): void
    {
        $this->getJson('/api/v1/auth/me')
            ->assertStatus(401)
            ->assertJson([
                'status' => false,
                'message' => 'غير مصرح لك بالدخول',
                'data' => null,
            ]);
    }

    public function test_me_rejects_a_bogus_token(): void
    {
        $this->withHeader('Authorization', 'Bearer not-a-real-token')
            ->getJson('/api/v1/auth/me')
            ->assertStatus(401)
            ->assertJson(['status' => false]);
    }

    // ───────────────────────────── logout ─────────────────────────────

    public function test_logout_revokes_only_the_current_token(): void
    {
        $user = User::factory()->create();
        $keptToken = $user->createToken('other-device')->plainTextToken;
        $headers = $this->bearerFor($user, 'this-device');

        $this->assertDatabaseCount('personal_access_tokens', 2);

        $this->withHeaders($headers)
            ->postJson('/api/v1/auth/logout')
            ->assertOk()
            ->assertJson(['status' => true, 'message' => 'تم تسجيل الخروج بنجاح', 'data' => null]);

        // The used token is gone...
        $this->assertDatabaseCount('personal_access_tokens', 1);
        $this->forgetAuthenticatedUser();
        $this->withHeaders($headers)->getJson('/api/v1/auth/me')->assertStatus(401);

        // ...but the other device is still signed in.
        $this->forgetAuthenticatedUser();
        $this->withHeader('Authorization', 'Bearer '.$keptToken)
            ->getJson('/api/v1/auth/me')
            ->assertOk();
    }

    public function test_logout_requires_authentication(): void
    {
        $this->postJson('/api/v1/auth/logout')->assertStatus(401);
    }

    public function test_logout_all_revokes_every_token(): void
    {
        $user = User::factory()->create();
        $otherToken = $user->createToken('other-device')->plainTextToken;
        $headers = $this->bearerFor($user, 'this-device');

        $this->withHeaders($headers)
            ->postJson('/api/v1/auth/logout-all')
            ->assertOk()
            ->assertJson(['status' => true, 'data' => null]);

        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->forgetAuthenticatedUser();
        $this->withHeader('Authorization', 'Bearer '.$otherToken)
            ->getJson('/api/v1/auth/me')
            ->assertStatus(401);
    }

    public function test_logout_all_requires_authentication(): void
    {
        $this->postJson('/api/v1/auth/logout-all')->assertStatus(401);
    }

    // ───────────────────────────── throttling ─────────────────────────────

    public function test_login_is_rate_limited_to_six_attempts_per_minute(): void
    {
        User::factory()->create(['email' => 'user@printing.ly']);

        for ($attempt = 1; $attempt <= 6; $attempt++) {
            $this->postJson('/api/v1/auth/login', [
                'login' => 'user@printing.ly', 'password' => 'wrong-password',
            ])->assertStatus(422);
        }

        $this->postJson('/api/v1/auth/login', [
            'login' => 'user@printing.ly', 'password' => 'wrong-password',
        ])->assertStatus(429)->assertJson([
            'status' => false,
            'message' => 'عدد المحاولات كبير، يرجى المحاولة لاحقاً',
        ]);
    }
}
