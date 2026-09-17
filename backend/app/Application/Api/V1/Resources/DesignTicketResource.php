<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A design ticket as every screen reads it.
 *
 * **The four `can_*` flags are the point of this resource.** Whether a button may be drawn is not
 * a permission alone: it is the permission **and** the status **and** this reader's role on this
 * particular ticket — a designer may accept a pool ticket and not a colleague's, may upload only
 * after accepting, and may never review their own work. Three conditions, each with its own
 * reason, evaluated in one place.
 *
 * A client that recomputed them would be a second implementation of the state machine written in
 * another language, and it would drift the first time a rule changed — the app would draw a button
 * the API then refuses, which reads to the user as the app being broken. The same argument
 * `OrderResource` makes for publishing its transitions and `ShortageResource` for its own.
 *
 * **`customer_name` is the snapshot, not a join.** A designer holds no grant on `customers`, so
 * the card has to be renderable without one — that is what the column is for.
 *
 * @mixin DesignTicket
 */
class DesignTicketResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var User|null $reader */
        $reader = $request->user();

        return [
            'id' => $this->id,
            'code' => $this->code,

            'title' => $this->title,
            'description' => $this->description,
            'instructions' => $this->instructions,

            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'is_open' => $this->status->isOpen(),
            'is_closed' => $this->status->isClosed(),

            // Published for the same reason `ShortageResource` publishes its own: the map lives
            // in one enum, and a client holding a copy would offer a move the API refuses.
            'available_transitions' => array_map(
                fn ($status): array => ['value' => $status->value, 'label' => $status->label()],
                $this->status->allowedNext(),
            ),

            // The snapshot — see the class docblock. `customer_id` travels beside it so a reader
            // who *does* hold `customers.view` can still follow the link.
            'customer_id' => $this->customer_id,
            'customer_name' => $this->customer_name,

            'order_id' => $this->order_id,
            'order' => $this->whenLoaded('order', fn (): ?array => $this->order === null ? null : [
                'id' => $this->order->id,
                'code' => $this->order->code,
                'is_archived' => $this->order->trashed(),
            ]),

            'requester' => $this->whenLoaded('requester', fn (): ?array => $this->requester === null ? null : [
                'id' => $this->requester->id,
                'name' => $this->requester->name,
            ]),

            // **Two people, deliberately.** The first is who it was addressed to, the second is
            // who actually took it — a reassignment moves one and never the other, and «لا تضيع
            // هوية المصمم الذي استلم الطلب» is about the second.
            'designer' => $this->whenLoaded('designer', fn (): ?array => $this->designer === null ? null : [
                'id' => $this->designer->id,
                'name' => $this->designer->name,
            ]),
            'accepted_by' => $this->whenLoaded('acceptedBy', fn (): ?array => $this->acceptedBy === null ? null : [
                'id' => $this->acceptedBy->id,
                'name' => $this->acceptedBy->name,
            ]),
            'accepted_at' => $this->accepted_at?->toIso8601String(),

            // True when nobody has been named and nobody has taken it — what a designer filters
            // by to find work. Derived here rather than by the client comparing two nulls.
            'is_in_shared_pool' => $this->assigned_designer_id === null && ! $this->isAccepted(),

            'approved_by' => $this->whenLoaded('approvedBy', fn (): ?array => $this->approvedBy === null ? null : [
                'id' => $this->approvedBy->id,
                'name' => $this->approvedBy->name,
            ]),
            'completed_at' => $this->completed_at?->toIso8601String(),

            // What the approval put on the customer's account — the output of the whole flow.
            'approved_customer_design_id' => $this->approved_customer_design_id,
            'approved_design' => $this->whenLoaded(
                'approvedDesign',
                fn () => $this->approvedDesign === null
                    ? null
                    : new CustomerDesignResource($this->approvedDesign),
            ),

            'cancellation_reason' => $this->cancellation_reason,

            'versions_count' => $this->whenCounted('versions'),

            'attachments' => DesignTicketFileResource::collection(
                $this->whenLoaded('attachments'),
            ),
            'versions' => DesignTicketFileResource::collection(
                $this->whenLoaded('versions'),
            ),

            // ── what this reader may do, here, now ──
            'can_accept' => $this->readerCanAccept($reader),
            'can_submit' => $this->readerCanSubmit($reader),
            'can_review' => $this->readerCanReview($reader),
            'can_assign' => $this->status->isOpen()
                && $reader?->can(PermissionName::AssignDesignTickets->value) === true,
            'can_manage' => $this->status->isOpen()
                && $reader?->can(PermissionName::ManageDesignTickets->value) === true,

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }

    /**
     * Every condition `AcceptDesignTicket` checks, asked ahead of time.
     *
     * The action is still the authority — this is what lets the app avoid making a request it
     * knows will be refused, not what makes the refusal.
     */
    private function readerCanAccept(?User $reader): bool
    {
        return $reader !== null
            && $this->status->isOpen()
            && ! $this->isAccepted()
            && $this->isWorkableBy($reader)
            && $reader->can(PermissionName::AcceptDesignTickets->value);
    }

    private function readerCanSubmit(?User $reader): bool
    {
        return $reader !== null
            && $this->status->acceptsSubmissions()
            && $this->isAccepted()
            && $this->isWorkableBy($reader)
            && $reader->can(PermissionName::SubmitDesignTickets->value);
    }

    /**
     * **Answers false for the person who uploaded the version**, which is the flag that carries
     * the separation of execution from approval onto the screen.
     *
     * Without it an administrator who drew the artwork would be shown two buttons that the domain
     * then refuses — and would reasonably read that as a bug rather than as a control.
     */
    private function readerCanReview(?User $reader): bool
    {
        if ($reader === null
            || ! $this->status->isOpen()
            || ! $reader->can(PermissionName::ReviewDesignTickets->value)) {
            return false;
        }

        $pending = $this->pendingVersion();

        return $pending !== null
            && (int) $pending->uploaded_by_user_id !== (int) $reader->getKey();
    }
}
