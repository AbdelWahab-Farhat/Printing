<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Customer\Models\CustomerDesign;
use App\Support\Media\HasStoredFile;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * The second or a later image of a design version (DESIGN-VERSION-IMAGES.md §4).
 *
 * **Face 1 is the version row itself**, so this only ever holds positions 2 and up — see
 * {@see DesignTicketFile::faces()} for the whole list in order.
 *
 * Nothing is fillable: the file columns come from a stored upload, and `customer_design_id` is
 * the record of an approval.
 */
class DesignTicketFileFace extends Model
{
    use Auditable, HasStoredFile, SoftDeletes;

    /**
     * @return array<string, mixed>
     */
    protected function casts(): array
    {
        return [
            'position' => 'integer',
            'size_bytes' => 'integer',
            'width_px' => 'integer',
            'height_px' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<DesignTicketFile, $this>
     */
    public function version(): BelongsTo
    {
        return $this->belongsTo(DesignTicketFile::class, 'design_ticket_file_id');
    }

    /**
     * @return BelongsTo<CustomerDesign, $this>
     */
    public function customerDesign(): BelongsTo
    {
        return $this->belongsTo(CustomerDesign::class);
    }
}
