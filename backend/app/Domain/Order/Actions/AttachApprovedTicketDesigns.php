<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\Support\PrintColors;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Models\Order;

/**
 * **An approved «تصميم طلبية» is put on its order** (owner, 2026-11-11; PRINT-COLORS.md §11).
 * This reverses DESIGN-TICKETS-DESIGN.md §12 Q5, which left it to a checkbox.
 *
 * For every completed ticket linked to [$order] whose approved library design is not yet among
 * the order's versions: add it as a new version, approve it on the order straight away
 * («معتمد», the owner's choice), and give it the approved version's colours (else the brief's).
 * Approving goes through {@see ReviewOrderDesign}, so an earlier approved version is superseded
 * exactly as when staff approve one by hand.
 *
 * **Only while the order takes artwork.** Called on approval, and again by
 * {@see ChangeOrderStatus} whenever an order stands in a status that does — so a design approved
 * while the order was in «نواقص» lands the moment it comes back. A closed or cancelled order is
 * left alone. Idempotent: an attached design is never attached twice.
 */
final class AttachApprovedTicketDesigns
{
    public function __construct(
        private readonly AddOrderDesign $addDesign,
        private readonly ReviewOrderDesign $reviewDesign,
    ) {}

    public function __invoke(Order $order, ?User $actor = null): void
    {
        if ($order->status->isClosed() || ! $order->designsAreEditable()) {
            return;
        }

        $tickets = DesignTicket::query()
            ->where('order_id', $order->getKey())
            ->where('status', DesignTicketStatus::Completed)
            ->whereNotNull('approved_customer_design_id')
            ->orderBy('completed_at')
            ->orderBy('id')
            ->get();

        if ($tickets->isEmpty()) {
            return;
        }

        $attached = $order->designs()->pluck('customer_design_id')->map(intval(...))->all();

        foreach ($tickets as $ticket) {
            $designId = (int) $ticket->approved_customer_design_id;

            if (in_array($designId, $attached, true)) {
                continue;
            }

            $version = ($this->addDesign)($order, $designId);

            $colors = $this->approvedColors($ticket);

            if ($colors !== null && $version->print_colors !== $colors) {
                $version->forceFill(['print_colors' => $colors])->save();
            }

            ($this->reviewDesign)($order, $version, OrderDesignStatus::Approved, null, $actor);

            $attached[] = $designId;
        }

        $order->unsetRelation('designs');
    }

    /**
     * The colours the approved version was drawn in, or the brief's when it carries none.
     *
     * @return list<array<string, mixed>>|null
     */
    private function approvedColors(DesignTicket $ticket): ?array
    {
        /** @var DesignTicketFile|null $approved */
        $approved = $ticket->files()
            ->where('kind', DesignTicketFileKind::Submission)
            ->where('status', DesignSubmissionStatus::Approved)
            ->orderByDesc('version')
            ->first();

        return PrintColors::normalise($approved?->print_colors ?? $ticket->print_colors);
    }
}
