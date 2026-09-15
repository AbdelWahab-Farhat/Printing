<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers\Concerns;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

/**
 * The reader narrowing, applied to a single bound ticket.
 *
 * **`design_tickets.view` is a grant, not a scope.** Holding it says a reader may use this
 * section; it does not say which tickets are theirs. Without this every route that binds
 * `{ticket}` would let any designer read a colleague's work by guessing an id — so every such
 * route calls this, on both controllers that have one.
 *
 * **A 404, never a 403**, and that is the honest answer rather than the softer one: a reader
 * without `design_tickets.view_all` has no business learning that a colleague's ticket exists,
 * and «ليس لديك صلاحية» on a specific id confirms that it does.
 *
 * The list does the same narrowing in SQL instead — see `FiltersDesignTickets` — because a page
 * that fetched rows and then dropped them would paginate short. The two are deliberately written
 * twice; only one of them can be a query.
 *
 * A trait rather than a method on the ticket controller, because the comment controller needs it
 * too and one controller reaching into another is a dependency neither of them should have.
 */
trait NarrowsDesignTickets
{
    /**
     * @param  bool  $onlyWhenClosed  {@see DesignTicketController::accept()}'s exception, and
     *                                nothing else's: an open ticket is left to the domain, which
     *                                refuses it in words naming whoever holds it.
     */
    protected function refuseUnlessVisibleTicket(
        Request $request,
        DesignTicket $ticket,
        bool $onlyWhenClosed = false,
    ): void {
        if ($request->user()?->can(PermissionName::ViewAllDesignTickets->value) === true) {
            return;
        }

        if ($onlyWhenClosed && $ticket->status->isOpen()) {
            return;
        }

        if (! $ticket->isVisibleTo($request->user())) {
            throw new NotFoundHttpException;
        }
    }
}
