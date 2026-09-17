<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\Enums\DesignKind;
use App\Domain\Customer\Exceptions\TooManyCustomerDesigns;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerDesign;
use App\Support\Media\StoreUploadedFile;
use Illuminate\Http\UploadedFile;

/**
 * Stores a customer's artwork and records it against them.
 *
 * The file goes through {@see StoreUploadedFile}, which owns the three habits this action used
 * to carry itself — the type sniffed from the bytes, the checksum taken before the move, and a
 * generated name. What is left here is what is about a *customer's design* rather than about
 * any file:
 *
 * 1. **The upload is idempotent on the checksum.** A dropped connection means the caller does
 *    not know whether the request landed, so it must retry — and a retry must not leave two
 *    copies of the same artwork. Finding the file already here answers with the existing row,
 *    before anything is written.
 * 2. **A customer holds at most fifty.** The designs travel inside the customer's own screens,
 *    so an unbounded library makes them heavier for everybody who opens one.
 * 3. **A PDF has pages, not pixels**, so its measurements are dropped rather than trusted —
 *    `getimagesize` on a PDF returns false anyway, and saying so on purpose beats letting it
 *    happen by accident.
 * 4. **The label defaults from the filename.** The label is the whole way staff tell two designs
 *    apart — there are no PDF thumbnails — and an unnamed row is one nobody dares print from.
 *
 * **No transaction.** One insert, and no primary flag to juggle.
 */
final class UploadCustomerDesign
{
    public function __construct(private readonly StoreUploadedFile $storeFile) {}

    /**
     * @return array{0: CustomerDesign, 1: bool} the design, and whether it was created now
     */
    public function __invoke(
        Customer $customer,
        UploadedFile $file,
        ?string $label = null,
        ?string $notes = null,
    ): array {
        // Answered before anything is written: a retry must cost nothing and change nothing.
        // The checksum is recomputed here rather than taken from a stored file, because the
        // whole point is to answer *without* having stored anything.
        $checksum = hash_file('sha256', (string) $file->getRealPath());

        $existing = $customer->designs()->where('checksum', $checksum)->first();
        if ($existing !== null) {
            return [$existing, false];
        }

        $limit = (int) config('media.customer_designs.max_per_customer');
        if ($customer->designs()->count() >= $limit) {
            throw new TooManyCustomerDesigns($limit);
        }

        $stored = ($this->storeFile)(
            $file,
            (string) config('media.customer_designs.disk'),
            "customer-designs/{$customer->getKey()}",
        );

        $kind = DesignKind::fromMimeType($stored->mimeType);

        $design = $customer->designs()->create([
            'disk' => $stored->disk,
            'path' => $stored->path,
            'original_filename' => $stored->originalFilename,
            'mime_type' => $stored->mimeType,
            'kind' => $kind,
            'size_bytes' => $stored->sizeBytes,
            'checksum' => $stored->checksum,
            'width_px' => $kind === DesignKind::Image ? $stored->widthPx : null,
            'height_px' => $kind === DesignKind::Image ? $stored->heightPx : null,
            'label' => $label ?? pathinfo($stored->originalFilename, PATHINFO_FILENAME),
            'notes' => $notes,
        ]);

        return [$design, true];
    }
}
