<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Identity\Enums\RoleName;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Spatie\Permission\Models\Role;

/**
 * @mixin Role
 */
class RoleResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $known = RoleName::tryFrom($this->name);

        return [
            'id' => $this->id,
            'name' => $this->name,
            // Falls back to the raw name for roles the business adds later, which the code
            // knows nothing about and does not need to.
            'label' => $known?->label() ?? $this->name,

            // An administrator's access comes from the gate, not from rows in a pivot table, so
            // its permission list is empty while its actual access is total. Saying so
            // explicitly stops that looking like a bug.
            'grants_everything' => $known === RoleName::Admin,

            'permissions' => $this->whenLoaded(
                'permissions',
                fn () => $this->permissions->pluck('name')->values(),
            ),
        ];
    }
}
