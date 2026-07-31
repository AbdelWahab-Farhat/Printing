<?php

declare(strict_types=1);

namespace App\Domain\Identity;

use App\Domain\Identity\Actions\CreateRole;
use App\Domain\Identity\Actions\DeleteRole;
use App\Domain\Identity\Actions\UpdateRole;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Collection;

/**
 * The Identity module's front door for everything about roles and access.
 *
 * Other modules ask here rather than reaching for Spatie's models directly, so the day roles
 * are stored or cached differently, only this class changes.
 */
class AccessService
{
    public function __construct(
        private readonly CreateRole $createRole,
        private readonly UpdateRole $updateRole,
        private readonly DeleteRole $deleteRole,
    ) {}

    /**
     * @return Collection<int, Role>
     */
    public function roles(): Collection
    {
        $roles = Role::query()->with('permissions')->orderBy('id')->get();

        // loadCount on the fetched models, not withCount on the query. Spatie resolves the user
        // model from the role's own guard_name, and withCount builds the relation against a bare
        // instance that has no attributes yet — so the guard is null and it blows up.
        $roles->loadCount('users');

        return $roles;
    }

    /**
     * @param  list<string>  $permissions
     */
    public function createRole(string $name, array $permissions = []): Role
    {
        return ($this->createRole)($name, $permissions);
    }

    /**
     * @param  list<string>|null  $permissions
     */
    public function updateRole(Role $role, string $name, ?array $permissions = null): Role
    {
        return ($this->updateRole)($role, $name, $permissions);
    }

    public function deleteRole(Role $role): void
    {
        ($this->deleteRole)($role);
    }

    /**
     * @param  list<string>  $roleNames
     */
    public function syncUserRoles(User $user, array $roleNames): User
    {
        $user->syncRoles($roleNames);

        return $user->load('roles');
    }
}
