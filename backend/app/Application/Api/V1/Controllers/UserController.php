<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\User\SyncUserRolesRequest;
use App\Application\Api\V1\Resources\UserResource;
use App\Application\Controller;
use App\Domain\Identity\Models\User;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * Users
 *
 * Staff accounts and the roles they hold. Managing access is an administrator's job.
 */
class UserController extends Controller
{
    use ResponseTrait;

    /**
     * List users
     */
    public function index(Request $request): JsonResponse
    {
        Gate::authorize('manage users');

        $perPage = min(max((int) $request->integer('per_page', 15), 1), 100);

        $users = User::query()
            ->with('roles')
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = '%'.trim((string) $request->string('search')).'%';

                $query->where(function ($query) use ($term) {
                    $query->where('name', 'ilike', $term)
                        ->orWhere('email', 'ilike', $term)
                        ->orWhere('phone', 'like', $term);
                });
            })
            ->orderBy('id')
            ->paginate($perPage);

        return $this->successWithPagination(UserResource::collection($users));
    }

    /**
     * Set a user's roles
     *
     * Replaces the whole set: send every role the user should end up with. An empty array
     * removes them all.
     */
    public function syncRoles(SyncUserRolesRequest $request, User $user): JsonResponse
    {
        Gate::authorize('manage users');

        $user->syncRoles($request->roleNames());

        return $this->success(
            new UserResource($user->load('roles')),
            'تم تحديث أدوار المستخدم بنجاح',
        );
    }
}
