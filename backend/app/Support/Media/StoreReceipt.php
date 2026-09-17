<?php

declare(strict_types=1);

namespace App\Support\Media;

use App\Domain\Customer\Actions\UploadCustomerDesign;
use App\Domain\Order\Actions\RecordOrderPayment;
use App\Domain\Shortage\Actions\RecordShortageSupply;
use Illuminate\Http\UploadedFile;

/**
 * Writes a receipt (الواصل) to the media disk and describes what it wrote.
 *
 * **Two callers, one habit.** A customer's payment proves itself with the paper they send us
 * ({@see RecordOrderPayment}); a sack bought to close a نقص proves itself with whatever the shop
 * next door wrote ({@see RecordShortageSupply}). Different rules about whether the paper is
 * *required* — the first demands it for a transfer, the second never does — but the same five
 * columns, the same private disk and the same refusal to let a client choose a path. The
 * directory is the caller's to name, which is the only thing that differs between them.
 *
 * **That the directory is a parameter is the whole reason this class is here and not in the
 * order context.** `design-tickets` and `main` each pulled this apart on their own — one into
 * `Order\Actions\StorePaymentReceipt`, typed on an `Order` and naming its own folder, the other
 * into this. Typing it on an order is the older shape: it cannot serve a نقص, which has no order
 * behind it and is the second caller.
 *
 * The file goes through {@see StoreUploadedFile} — the generated name, the sniffed extension and
 * the checksum all live there now. What is left here is the shape of the columns a payment row
 * expects, and one decision:
 *
 * **Not idempotent, deliberately**, which is the one place this parts from
 * {@see UploadCustomerDesign}. A design is a thing the customer owns once; a receipt is evidence
 * attached to a particular entry, and two entries backed by the same bank transfer each need
 * their own row pointing at it. The checksum is still recorded — it answers "is this the same
 * paper we were sent last time?" without opening either — it is simply not a uniqueness key.
 *
 * The file is written inside the caller's transaction, so a payment refused for exceeding what
 * is outstanding leaves an object behind with no row. That costs storage and nothing else — the
 * reverse, a row pointing at a file that was never written, would be an entry whose proof cannot
 * be produced.
 */
final class StoreReceipt
{
    public function __construct(private readonly StoreUploadedFile $storeFile) {}

    /**
     * @return array{
     *     receipt_disk: string,
     *     receipt_path: string,
     *     receipt_original_filename: string,
     *     receipt_size_bytes: int,
     *     receipt_checksum: string,
     * }
     */
    public function __invoke(string $directory, UploadedFile $file): array
    {
        $stored = ($this->storeFile)(
            $file,
            (string) config('media.payment_receipts.disk'),
            $directory,
        );

        return [
            'receipt_disk' => $stored->disk,
            'receipt_path' => $stored->path,
            'receipt_original_filename' => $stored->originalFilename,
            'receipt_size_bytes' => $stored->sizeBytes,
            'receipt_checksum' => $stored->checksum,
        ];
    }
}
