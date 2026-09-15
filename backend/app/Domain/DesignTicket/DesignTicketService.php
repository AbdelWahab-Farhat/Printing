<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket;

use App\Domain\DesignTicket\Actions\AcceptDesignTicket;
use App\Domain\DesignTicket\Actions\AssignDesignTicket;
use App\Domain\DesignTicket\Actions\AttachDesignTicketFile;
use App\Domain\DesignTicket\Actions\CancelDesignTicket;
use App\Domain\DesignTicket\Actions\CreateDesignTicket;
use App\Domain\DesignTicket\Actions\DeleteDesignTicketAttachment;
use App\Domain\DesignTicket\Actions\ReviewDesignVersion;
use App\Domain\DesignTicket\Actions\SubmitDesignVersion;
use App\Domain\DesignTicket\Actions\UpdateDesignTicket;
use App\Domain\DesignTicket\DTOs\DesignTicketData;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\DesignTicket\Queries\DesignTicketFilters;
use App\Domain\DesignTicket\Queries\DesignTicketListQuery;
use App\Domain\DesignTicket\Queries\DesignTicketStatusCountsQuery;
use App\Domain\Identity\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;

/**
 * The design ticket module's only public entry point.
 *
 * A door, not a place for logic — the work lives in the Actions and Queries behind it. Another
 * context calls this rather than reaching for `DesignTicket::query()`, which is what lets this one
 * change internally without a ripple.
 *
 * Today nothing outside calls it at all: the controller is the only consumer. It exists anyway,
 * because the first cross-context caller is coming — an order screen that wants to know whether
 * artwork has been requested — and adding the seam afterwards means finding every query somebody
 * wrote in the meantime.
 */
final class DesignTicketService
{
    public function __construct(
        private readonly DesignTicketListQuery $listQuery,
        private readonly DesignTicketStatusCountsQuery $statusCountsQuery,
        private readonly CreateDesignTicket $createTicket,
        private readonly UpdateDesignTicket $updateTicket,
        private readonly AssignDesignTicket $assignTicket,
        private readonly AcceptDesignTicket $acceptTicket,
        private readonly CancelDesignTicket $cancelTicket,
        private readonly AttachDesignTicketFile $attachFile,
        private readonly DeleteDesignTicketAttachment $deleteAttachment,
        private readonly SubmitDesignVersion $submitVersion,
        private readonly ReviewDesignVersion $reviewVersion,
    ) {}

    /**
     * @return LengthAwarePaginator<int, DesignTicket>
     */
    public function paginate(DesignTicketFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->listQuery)($filters, $perPage);
    }

    /**
     * @return array<string, int>
     */
    public function statusCounts(DesignTicketFilters $filters): array
    {
        return ($this->statusCountsQuery)($filters);
    }

    public function create(DesignTicketData $data, ?User $actor = null): DesignTicket
    {
        return ($this->createTicket)($data, $actor);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(DesignTicket $ticket, array $attributes): DesignTicket
    {
        return ($this->updateTicket)($ticket, $attributes);
    }

    public function assign(DesignTicket $ticket, ?User $designer, ?User $actor = null): DesignTicket
    {
        return ($this->assignTicket)($ticket, $designer, $actor);
    }

    public function accept(DesignTicket $ticket, User $designer): DesignTicket
    {
        return ($this->acceptTicket)($ticket, $designer);
    }

    public function cancel(DesignTicket $ticket, ?string $reason, ?User $actor = null): DesignTicket
    {
        return ($this->cancelTicket)($ticket, $reason, $actor);
    }

    public function attach(
        DesignTicket $ticket,
        UploadedFile $file,
        ?User $actor = null,
        ?string $note = null,
    ): DesignTicketFile {
        return ($this->attachFile)($ticket, $file, $actor, $note);
    }

    public function deleteAttachment(DesignTicketFile $file): void
    {
        ($this->deleteAttachment)($file);
    }

    public function submit(
        DesignTicket $ticket,
        UploadedFile $file,
        User $designer,
        ?string $note = null,
    ): DesignTicketFile {
        return ($this->submitVersion)($ticket, $file, $designer, $note);
    }

    public function review(
        DesignTicket $ticket,
        DesignTicketFile $version,
        DesignSubmissionStatus $verdict,
        ?string $note = null,
        ?User $actor = null,
    ): DesignTicketFile {
        return ($this->reviewVersion)($ticket, $version, $verdict, $note, $actor);
    }
}
