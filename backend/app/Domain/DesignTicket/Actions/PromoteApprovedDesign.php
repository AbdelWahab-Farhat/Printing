<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Order\Actions\AddOrderDesign;

/**
 * Puts the approved artwork onto the customer's account.
 *
 * **The step the whole feature exists for**: «بعد الاعتماد يتم حفظ التصميم تلقائيًا في حساب
 * الزبون». Everything before it is a conversation; this is the part that leaves something behind.
 *
 * **It copies the row, not the bytes.** The file already sits on the designs disk under the
 * ticket's folder, and `customer_designs` records the disk and the path per row — so pointing the
 * new row at the existing object is correct, costs nothing, and cannot fail halfway. Moving the
 * object would break that table's stated commitment that a file never moves and is never erased,
 * and would add a failure mode (object moved, insert failed) at the most sensitive point in the
 * system.
 *
 * **Idempotent through the checksum**, and that is inherited rather than written: if this artwork
 * is already in the customer's library — the same file uploaded by hand last week, or a retried
 * approval — the checksum index answers with the row that exists instead of a second copy. The
 * existing row is then stamped with the ticket, which is the correct outcome: the design is the
 * same design, and now it has a provenance.
 *
 * **The label comes from the ticket's title, not the filename.** `CustomerDesign` says the label
 * is the whole identification story, because there are no PDF thumbnails — and «تصميم كيس شحن —
 * أسود» is what somebody will search for months later, while `final_v3_FINAL.pdf` is not.
 *
 * Nothing here touches the order. Attaching the design to one is {@see AddOrderDesign}'s job and
 * a deliberate second step — see DESIGN-TICKETS-DESIGN.md §12 Q5.
 */
final class PromoteApprovedDesign
{
    public function __invoke(DesignTicket $ticket, DesignTicketFile $version): CustomerDesign
    {
        $existing = CustomerDesign::query()
            ->where('customer_id', $ticket->customer_id)
            ->where('checksum', $version->checksum)
            ->first();

        if ($existing !== null) {
            // Already theirs. Record where it came from — unless it already names a ticket, in
            // which case that earlier provenance is the true one and overwriting it would rewrite
            // history to say this request produced a file it merely re-approved.
            if ($existing->design_ticket_id === null) {
                $existing->forceFill([
                    'design_ticket_id' => $ticket->getKey(),
                    'designer_user_id' => $version->uploaded_by_user_id,
                    'approved_at' => now(),
                ])->save();
            }

            return $existing->refresh();
        }

        $design = new CustomerDesign([
            'disk' => $version->disk,
            'path' => $version->path,
            'original_filename' => $version->original_filename,
            'mime_type' => $version->mime_type,
            'kind' => $version->file_kind,
            'size_bytes' => $version->size_bytes,
            'checksum' => $version->checksum,
            'width_px' => $version->width_px,
            'height_px' => $version->height_px,
            'label' => $ticket->title,
            'notes' => $version->note,
        ]);

        $design->customer()->associate($ticket->customer_id);

        // Not fillable, and none of them may come from a request: they are the record of an
        // approval that happened.
        $design->forceFill([
            'design_ticket_id' => $ticket->getKey(),
            'designer_user_id' => $version->uploaded_by_user_id,
            'approved_at' => now(),
        ])->save();

        return $design->refresh();
    }
}
