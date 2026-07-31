<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Audit\Enums\AuditEvent;
use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Audit\Models\ActivityLog;
use App\Domain\Identity\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One line of history: who changed what, when, and from what to what.
 *
 * @mixin ActivityLog
 */
class ActivityLogResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $event = AuditEvent::tryFrom((string) $this->event);
        $subject = AuditSubject::tryFrom((string) $this->subject_type);

        return [
            'id' => $this->id,

            // Both the value and its Arabic label, the same bargain every enum in this API
            // makes: the client renders the label and branches on the value, and never keeps
            // its own translation table in step with ours.
            'event' => $this->event,
            'event_label' => $event?->label(),

            // The sentence stored when it happened, not one composed now. History that rewords
            // itself when the code changes is not history.
            'description' => $this->description,

            // A stable alias — 'product' — never a PHP class name. See AuditSubject.
            'subject_type' => $this->subject_type,
            'subject_type_label' => $subject?->label(),
            'subject_id' => $this->subject_id,

            // Null for anything no person did: a seeder, a console command, a queued job.
            // Saying so explicitly beats an empty object the client has to interpret.
            'causer' => $this->whenLoaded('causer', fn () => $this->causerSummary()),

            // What actually moved. `old` is absent on a creation and `attributes` on a
            // deletion, because there is no such half in either case.
            'changes' => [
                'old' => $this->attribute_changes?->get('old'),
                'attributes' => $this->attribute_changes?->get('attributes'),
            ],

            // Anything recorded by hand rather than by a model event — today, the permissions a
            // role gained or lost. Omitted entirely when there is none.
            'properties' => $this->when(
                $this->properties !== null && $this->properties->isNotEmpty(),
                fn () => $this->properties,
            ),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * Just enough to name the person: a history screen shows who, and links elsewhere for the
     * rest. A deleted user still resolves — `include_soft_deleted_subjects` and the fact that
     * users are soft deleted mean the trail never loses the name attached to a change.
     *
     * @return array<string, mixed>|null
     */
    private function causerSummary(): ?array
    {
        $causer = $this->causer;

        if ($causer === null) {
            return null;
        }

        return [
            'id' => $causer->getKey(),
            'type' => $causer->getMorphClass(),
            'name' => $causer instanceof User ? $causer->name : null,
        ];
    }
}
