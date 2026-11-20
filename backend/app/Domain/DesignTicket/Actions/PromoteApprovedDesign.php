<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\Customer\Enums\DesignKind;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\DesignTicket\Models\DesignTicketFileFace;
use App\Domain\Order\Actions\AddOrderDesign;
use App\Domain\Order\Actions\RefreshOrderDesignColors;

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
 *
 * **The print colors travel with the file** — the approved version's, or the brief's when the
 * version carries none (a designer on an app that predates the field). On a design already in
 * the library they fill an empty list and never overwrite one: somebody wrote those colors
 * against this exact file, and a re-approval is not a reason to replace their answer.
 */
final class PromoteApprovedDesign
{
    public function __construct(private readonly RefreshOrderDesignColors $refreshOrders) {}

    /**
     * **Every face becomes a library design** (DESIGN-VERSION-IMAGES.md §4), in position order.
     * Face 1's is returned — it is what `design_tickets.approved_customer_design_id` names — and
     * each later face records its own on its row, so the order can be given all of them.
     */
    public function __invoke(DesignTicket $ticket, DesignTicketFile $version): CustomerDesign
    {
        $colors = $version->print_colors ?? $ticket->print_colors;

        $first = $this->promoteFace($ticket, $version, $version, $colors, (string) $ticket->title);

        foreach ($version->extraFaces()->get() as $face) {
            $design = $this->promoteFace(
                $ticket,
                $version,
                $face,
                $colors,
                $ticket->title.' — '.self::arabicDigits($face->position),
            );

            $face->forceFill(['customer_design_id' => $design->getKey()])->save();
        }

        return $first;
    }

    /**
     * The library design ids of every face of an approved version, face 1 first.
     *
     * @return list<int>
     */
    public static function designIdsOf(DesignTicket $ticket): array
    {
        if ($ticket->approved_customer_design_id === null) {
            return [];
        }

        /** @var DesignTicketFile|null $approved */
        $approved = $ticket->files()
            ->where('status', DesignSubmissionStatus::Approved)
            ->first();

        $rest = $approved === null
            ? []
            : $approved->extraFaces()->whereNotNull('customer_design_id')
                ->pluck('customer_design_id')->map(intval(...))->all();

        return array_values(array_unique([(int) $ticket->approved_customer_design_id, ...$rest]));
    }

    private static function arabicDigits(int $number): string
    {
        return strtr((string) $number, ['0' => '٠', '1' => '١', '2' => '٢', '3' => '٣', '4' => '٤',
            '5' => '٥', '6' => '٦', '7' => '٧', '8' => '٨', '9' => '٩']);
    }

    /**
     * @param  list<array<string, mixed>>|null  $colors
     */
    private function promoteFace(
        DesignTicket $ticket,
        DesignTicketFile $version,
        DesignTicketFile|DesignTicketFileFace $face,
        ?array $colors,
        string $label,
    ): CustomerDesign {
        $existing = CustomerDesign::query()
            ->where('customer_id', $ticket->customer_id)
            ->where('checksum', $face->checksum)
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

            if ($existing->print_colors === null && $colors !== null) {
                $existing->print_colors = $colors;
                $existing->save();

                // An order already holding this file holds an empty copy of its colors.
                ($this->refreshOrders)($existing, null);
            }

            return $existing->refresh();
        }

        $design = new CustomerDesign([
            'disk' => $face->disk,
            'path' => $face->path,
            'original_filename' => $face->original_filename,
            'mime_type' => $face->mime_type,
            // Faces 2…N are images by rule; face 1 keeps the kind it was filed with, which on a
            // version uploaded before faces existed can be a PDF.
            'kind' => $face instanceof DesignTicketFile ? $face->file_kind : DesignKind::fromMimeType($face->mime_type),
            'size_bytes' => $face->size_bytes,
            'checksum' => $face->checksum,
            'width_px' => $face->width_px,
            'height_px' => $face->height_px,
            'label' => $label,
            'notes' => $version->note,
            'print_colors' => $colors,
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
