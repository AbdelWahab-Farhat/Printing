<?php

namespace App\Domain\Identity\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Domain\Identity\Enums\RoleName;
use App\Providers\AppServiceProvider;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

// Models live under app/Domain/, so Laravel's App\Models convention can no longer
// guess the factory. Every domain model names its factory explicitly.
#[UseFactory(UserFactory::class)]
#[Fillable(['name', 'email', 'phone', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, Notifiable;

    /**
     * Roles and permissions are stored against the `web` guard.
     *
     * Requests authenticate through Sanctum, but Sanctum is a token *transport* — it resolves to
     * the same `users` provider. Pinning the guard here stops Spatie from inferring `sanctum`
     * and then failing to match roles that were created under `web`, which is the usual first
     * bug when the two are combined.
     */
    protected string $guard_name = 'web';

    /**
     * Whether this user is an administrator — full access to everything, always.
     *
     * @see AppServiceProvider::boot() for the gate that enforces it.
     */
    public function isAdmin(): bool
    {
        return $this->hasRole(RoleName::Admin->value);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
