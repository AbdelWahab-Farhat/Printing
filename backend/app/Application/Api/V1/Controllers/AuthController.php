<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Auth\LoginRequest;
use App\Application\Api\V1\Requests\Auth\RegisterRequest;
use App\Application\Api\V1\Resources\UserResource;
use App\Application\Controller;
use App\Domain\Identity\AuthService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Authentication
 *
 * Register, sign in, and manage the current session's token.
 */
class AuthController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly AuthService $auth) {}

    /**
     * Register a new account
     *
     * Creates the user and returns an access token, so no second login call is needed.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->auth->register(
            name: $request->string('name')->toString(),
            email: $request->string('email')->toString(),
            phone: $request->string('phone')->toString(),
            password: $request->string('password')->toString(),
            deviceName: $request->string('device_name')->toString() ?: null,
        );

        return $this->created([
            'user' => new UserResource($result->user->load('roles')),
            'token' => $result->token,
        ], 'تم إنشاء الحساب بنجاح');
    }

    /**
     * Log in
     *
     * The `login` field accepts either the email address or the phone number.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->auth->login(
            login: $request->string('login')->toString(),
            password: $request->string('password')->toString(),
            deviceName: $request->string('device_name')->toString() ?: null,
        );

        return $this->success([
            'user' => new UserResource($result->user->load('roles')),
            'token' => $result->token,
        ], 'تم تسجيل الدخول بنجاح');
    }

    /**
     * Get the authenticated user
     *
     * Use this to validate a stored token on app start.
     */
    public function me(Request $request): JsonResponse
    {
        return $this->success(new UserResource($request->user()->load('roles')));
    }

    /**
     * Log out of this device
     *
     * Revokes only the token used for this request; other devices stay signed in.
     */
    public function logout(Request $request): JsonResponse
    {
        $this->auth->logout($request->user());

        return $this->successMessage('تم تسجيل الخروج بنجاح');
    }

    /**
     * Log out of every device
     *
     * Revokes all of this user's tokens.
     */
    public function logoutAll(Request $request): JsonResponse
    {
        $this->auth->logoutFromAllDevices($request->user());

        return $this->successMessage('تم تسجيل الخروج من جميع الأجهزة');
    }
}
