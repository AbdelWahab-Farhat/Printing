<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,

            // What the app puts on the employee's card, next to their name.
            'employee_code' => $this->employee_code,

            'roles' => $this->whenLoaded('roles', fn () => $this->roles->map(fn ($role) => [
                'name' => $role->name,
                'label' => RoleName::tryFrom($role->name)?->label() ?? $role->name,
            ])->values()),

            // The client should not have to know that "admin" is special — it asks the server.
            'is_admin' => $this->when($this->relationLoaded('roles'), fn () => $this->isAdmin()),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
