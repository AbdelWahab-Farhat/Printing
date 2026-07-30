<?php

declare(strict_types=1);

namespace App\Services;

use App\DTOs\AuthResult;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * All authentication business logic. Controllers only translate HTTP to these calls.
 */
class AuthService
{
    private const DEFAULT_DEVICE_NAME = 'api';

    /**
     * Create the account and hand back a ready-to-use token, so the client does not
     * have to follow registration with a second login round-trip.
     */
    public function register(string $name, string $email, string $phone, string $password, ?string $deviceName = null): AuthResult
    {
        $user = DB::transaction(fn (): User => User::create([
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            // The model casts `password` as 'hashed', so this is stored hashed.
            'password' => $password,
        ]));

        return new AuthResult($user, $this->issueToken($user, $deviceName));
    }

    /**
     * Authenticate by email *or* phone.
     *
     * @throws ValidationException when the credentials do not match.
     */
    public function login(string $login, string $password, ?string $deviceName = null): AuthResult
    {
        $user = User::query()
            ->where('email', $login)
            ->orWhere('phone', $login)
            ->first();

        // One message for both "no such user" and "wrong password" — telling them apart
        // would let an attacker enumerate registered accounts.
        if (! $user || ! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['بيانات الدخول غير صحيحة'],
            ]);
        }

        return new AuthResult($user, $this->issueToken($user, $deviceName));
    }

    /**
     * Revoke only the token used for the current request, leaving other devices signed in.
     */
    public function logout(User $user): void
    {
        $token = $user->currentAccessToken();

        // Under cookie/SPA auth this is a TransientToken, which has nothing to revoke.
        // Only a token that is actually persisted can be deleted. Checking for Model
        // rather than PersonalAccessToken keeps this working with a custom token model.
        if ($token instanceof Model) {
            $token->delete();
        }
    }

    /**
     * Revoke every token this user holds — the "sign out everywhere" action.
     */
    public function logoutFromAllDevices(User $user): void
    {
        $user->tokens()->delete();
    }

    private function issueToken(User $user, ?string $deviceName): string
    {
        return $user->createToken($deviceName ?: self::DEFAULT_DEVICE_NAME)->plainTextToken;
    }
}
