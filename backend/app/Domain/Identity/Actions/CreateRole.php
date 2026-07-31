<?php

declare(strict_types=1);

namespace App\Domain\Identity\Actions;

use App\Domain\Identity\Models\Role;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\PermissionRegistrar;

/**
 * Creates a role and grants it a set of permissions from the catalogue.
 */
final class CreateRole
{
    public function __construct(private readonly RecordRolePermissionChange $recordPermissionChange) {}

    /**
     * @param  list<string>  $permissions
     */
    public function __invoke(string $name, array $permissions = []): Role
    {
        $role = DB::transaction(function () use ($name, $permissions): Role {
            $role = Role::create(['name' => $name, 'guard_name' => 'web']);
            $role->syncPermissions($permissions);

            // The `created` entry covers the role's own columns; the permissions it was born
            // with live in a pivot table that fires no events, so they are recorded explicitly.
            ($this->recordPermissionChange)($role, [], $permissions);

            return $role;
        });

        // The cache is keyed globally, so a new role stays invisible to authorization checks
        // until it is cleared — including checks made by the very next request.
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        return $role->load('permissions');
    }
}
