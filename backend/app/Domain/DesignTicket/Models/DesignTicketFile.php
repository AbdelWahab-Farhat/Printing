<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Customer\Enums\DesignKind;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Models\OrderDesign;
use App\Support\Media\HasStoredFile;
use App\Support\Media\StoredFile;
use Database\Factories\DesignTicketFileFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One file on a design ticket — either what the employee sent or what the designer drew.
 *
 * **It holds its own bytes, unlike {@see OrderDesign}.** That model
 * points at the customer's library because every design an order prints is the customer's
 * property. A ticket's files are not: a brief is a reference photo, and a rejected draft is a
 * work conversation. Putting them in `customer_designs` would have broken the brief's own
 * criterion that only the approved design lands on the customer's account — and fixing that
 * afterwards would have meant filtering an endpoint that works today. On approval,
 * `PromoteApprovedDesign` copies the winner across.
 *
 * **Nothing here is fillable but the two free-text fields.** The media columns are written from a
 * {@see StoredFile}, which is produced from the bytes rather than the request;
 * `kind`, `version` and `status` are the row's identity and its verdict, and a request body that
 * could set them could number a version itself or mark its own work approved.
 *
 * `file_kind` reuses {@see DesignKind} rather than declaring a second enum: it answers the same
 * question for the same reason — whether the app can draw this thing or must hand it to the
 * system's own viewer.
 */
#[UseFactory(DesignTicketFileFactory::class)]
#[Fillable(['note'])]
class DesignTicketFile extends Model
{
    /** @use HasFactory<DesignTicketFileFactory> */
    use Auditable, HasFactory, HasStoredFile, SoftDeletes;

    /**
     * @return array<string, mixed>
     */
    protected function casts(): array
    {
        return [
            'kind' => DesignTicketFileKind::class,
            'file_kind' => DesignKind::class,
            'status' => DesignSubmissionStatus::class,
            'size_bytes' => 'integer',
            'width_px' => 'integer',
            'height_px' => 'integer',
            'version' => 'integer',
            'reviewed_at' => 'datetime',
        ];
    }

    public function isSubmission(): bool
    {
        return $this->kind === DesignTicketFileKind::Submission;
    }

    /** Waiting on a verdict. Only ever true of a submission — the CHECK constraint sees to that. */
    public function isAwaitingReview(): bool
    {
        return $this->status === DesignSubmissionStatus::Proposed;
    }

    /**
     * A name to show when the uploader gave none.
     *
     * The same fallback ladder {@see CustomerDesign::displayName()} climbs, with the version in
     * the middle: a submission is identified in conversation by its number — «النسخة الثالثة» —
     * long before anybody reads its filename.
     */
    public function displayName(): string
    {
        if ($this->isSubmission()) {
            return "النسخة {$this->version}";
        }

        return $this->original_filename ?? "مرفق #{$this->getKey()}";
    }

    /**
     * @return BelongsTo<DesignTicket, $this>
     */
    public function ticket(): BelongsTo
    {
        return $this->belongsTo(DesignTicket::class, 'design_ticket_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_user_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
