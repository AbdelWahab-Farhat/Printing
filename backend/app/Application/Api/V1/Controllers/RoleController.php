<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Resources\RoleResource;
use App\Application\Controller;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;
use Spatie\Permission\Models\Role;

/**
 * Roles
 *
 * Job roles that can be given to staff. Permissions attach to a role, and a member of staff
 * gets their access by holding it — so changing what a job may do is one edit to the role
 * rather than a change to every person doing that job.
 *
 * The `admin` role is the exception: it passes every authorization check by rule, so its
 * permission list stays empty while its access is total.
 */
class RoleController extends Controller
{
    use ResponseTrait;

    /**
     * List roles
     */
    public function index(): JsonResponse
    {
        // Only an administrator manages access. Nobody holds the `manage users` permission yet,
        // so today this passes for administrators alone — and the day that permission is
        // created and granted to a role, the holders of that role pass too, with no code change.
        Gate::authorize('manage users');

        return $this->success(RoleResource::collection(Role::query()->with('permissions')->orderBy('id')->get()));
    }
}
