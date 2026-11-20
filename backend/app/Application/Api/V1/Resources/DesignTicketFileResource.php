<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\DesignTicket\Models\DesignTicketFileFace;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One file on a ticket — a brief the employee sent, or a version the designer drew.
 *
 * Shaped as closely as possible to {@see CustomerDesignResource}, and that is a decision rather
 * than an accident: the app's `DesignThumbnail` and `DesignViewer` already draw that payload, and
 * two nearly-identical shapes would have meant two widgets that drift. `kind`, `file_url`,
 * `mime_type`, the dimensions and `preview_url` all mean exactly what they mean there.
 *
 * The version fields are null on a brief — the CHECK constraint on the table guarantees it — so a
 * client can render one list and branch on `file_kind`.
 *
 * @mixin DesignTicketFile
 */
class DesignTicketFileResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'design_ticket_id' => $this->design_ticket_id,

            // `brief` | `submission` — which half of the conversation this belongs to.
            'kind' => $this->kind->value,
            'kind_label' => $this->kind->label(),

            'label' => $this->displayName(),
            'note' => $this->note,
            // The inks a version was drawn in — empty on a brief, and on a version sent without.
            'print_colors' => $this->print_colors ?? [],

            // `image` or `pdf` — whether the app can draw this itself or must hand it to the
            // system viewer. The same key `CustomerDesignResource` publishes, so the same widget
            // reads both.
            'file_kind' => $this->file_kind->value,
            'file_kind_label' => $this->file_kind->label(),
            'mime_type' => $this->mime_type,

            'original_filename' => $this->original_filename,
            'size_bytes' => $this->size_bytes,
            'width_px' => $this->width_px,
            'height_px' => $this->height_px,

            // Generated per request from the disk the file actually lives on, and never stored.
            // On a private bucket it is a signed link that expires.
            'file_url' => $this->url(),

            // Reserved, exactly as on a customer design: a server-rendered first page for a PDF
            // is a follow-up, and having the key now means it can land without an app release.
            'preview_url' => null,

            // **Every image of a version, face 1 first** (DESIGN-VERSION-IMAGES.md §5). Face 1 is
            // this row, so the fields above stay what an older app draws. One entry on a brief and
            // on a version uploaded before faces existed. Sent only where the faces were loaded,
            // so a response is never a lazy load per row.
            'faces' => $this->when(
                $this->relationLoaded('extraFaces'),
                fn (): array => array_map(
                    fn (DesignTicketFile|DesignTicketFileFace $face): array => [
                        'position' => $face instanceof DesignTicketFileFace ? $face->position : 1,
                        'file_url' => $face->url(),
                        'mime_type' => $face->mime_type,
                        'original_filename' => $face->original_filename,
                        'size_bytes' => $face->size_bytes,
                        'width_px' => $face->width_px,
                        'height_px' => $face->height_px,
                    ],
                    $this->resource->faces(),
                ),
            ),

            // ── the version story; all null on a brief ──
            'version' => $this->version,
            'status' => $this->status?->value,
            'status_label' => $this->status?->label(),
            'is_awaiting_review' => $this->isAwaitingReview(),

            // What the reviewer asked to be changed. The whole reason a revision round exists.
            'review_note' => $this->review_note,
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'reviewer' => $this->whenLoaded('reviewer', fn (): ?array => $this->reviewer === null ? null : [
                'id' => $this->reviewer->id,
                'name' => $this->reviewer->name,
            ]),

            'uploader' => $this->whenLoaded('uploader', fn (): ?array => $this->uploader === null ? null : [
                'id' => $this->uploader->id,
                'name' => $this->uploader->name,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
