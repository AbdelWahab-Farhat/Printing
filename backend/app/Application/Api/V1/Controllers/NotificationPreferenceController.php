<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Notification\SetPushPreferenceRequest;
use App\Application\Api\V1\Resources\PushPreferenceGroupResource;
use App\Application\Controller;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\NotificationService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;

/**
 * Employee notification settings
 *
 * Which group notifications wake an employee's phone — Docs/notifications/PUSH-PREFERENCES.md.
 * Set by an administrator (`users.manage`), not by the employee.
 *
 * **Push only.** Every notification still lands in the bell; this only decides whether the phone
 * is woken for it. Notifications addressed to the employee by name are not listed and always
 * push.
 */
class NotificationPreferenceController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly NotificationService $notifications) {}

    /**
     * An employee's push settings
     *
     * Only the group notifications this employee can receive, in catalogue order. A switch never
     * touched reads `push: true`.
     */
    public function show(User $user): JsonResponse
    {
        return $this->success(PushPreferenceGroupResource::collection(
            $this->notifications->pushPreferencesFor($user),
        ));
    }

    /**
     * Turn one push switch on or off
     *
     * `scope` is omitted for a type that is one switch, and is an order status for
     * `order.status`. A type that always pushes, or a status that never rings, answers 422.
     * Returns the employee's settings after the change.
     */
    public function update(SetPushPreferenceRequest $request, User $user): JsonResponse
    {
        $this->notifications->setPushPreference(
            $user,
            $request->notificationType(),
            $request->scope(),
            $request->boolean('push'),
        );

        return $this->success(
            PushPreferenceGroupResource::collection($this->notifications->pushPreferencesFor($user)),
            'تم الحفظ',
        );
    }
}
