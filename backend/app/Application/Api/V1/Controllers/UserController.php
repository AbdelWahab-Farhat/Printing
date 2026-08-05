<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\User\StoreUserRequest;
use App\Application\Api\V1\Requests\User\SyncUserRolesRequest;
use App\Application\Api\V1\Resources\UserResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Identity\AccessService;
use App\Domain\Identity\Models\User;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Users
 *
 * Staff accounts and the roles they hold. Access is declared on the routes: reading needs
 * `users.view`, changing someone's roles needs `users.manage`.
 */
class UserController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(private readonly AccessService $access) {}

    /**
     * List users
     */
    public function index(Request $request): JsonResponse
    {
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
     * Create a staff account
     *
     * **Administrators only**, and not by permission: `users.create` is a gate ability rather
     * than a case in the permission catalogue, so it cannot be ticked onto a role. See
     * `AppServiceProvider::boot()` for why, and for the one edit that delegates it later.
     *
     * The account is usable immediately — the password given here is the one the employee signs
     * in with. No token is issued: the person holding the phone is not the person being created.
     */
    public function store(StoreUserRequest $request): JsonResponse
    {
        $user = $this->access->createUser(
            $request->string('name')->toString(),
            $request->string('email')->toString(),
            $request->string('phone')->toString(),
            $request->string('password')->toString(),
            $request->roleNames(),
        );

        return $this->created(new UserResource($user), 'تم إنشاء حساب الموظف بنجاح');
    }

    /**
     * Set a user's roles
     *
     * Replaces the whole set: send every role the user should end up with. An empty array
     * removes them all.
     */
    public function syncRoles(SyncUserRolesRequest $request, User $user): JsonResponse
    {
        $updated = $this->access->syncUserRoles($user, $request->roleNames());

        return $this->success(new UserResource($updated), 'تم تحديث أدوار المستخدم بنجاح');
    }

    /**
     * A user's history
     *
     * Every change to this account, newest first — including the changes someone else made to
     * it. To see what this user *did* rather than what was done to them, filter any history
     * endpoint with `causer_id`.
     *
     * Role assignments are not here: a user's roles live in a pivot table that fires no model
     * events. The change is recorded against the role instead — see `GET /roles/{role}/logs`.
     */
    public function logs(ActivityLogFilterRequest $request, User $user, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse($request, $user, $audit);
    }
}
