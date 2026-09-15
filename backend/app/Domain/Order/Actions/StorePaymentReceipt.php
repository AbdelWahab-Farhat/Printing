<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\Actions\UploadCustomerDesign;
use App\Domain\Order\Models\Order;
use App\Support\Media\StoreUploadedFile;
use Illuminate\Http\UploadedFile;

/**
 * Writes a payment's receipt (الواصل) to the media disk and describes what it wrote.
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
final class StorePaymentReceipt
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
    public function __invoke(Order $order, UploadedFile $file): array
    {
        $stored = ($this->storeFile)(
            $file,
            (string) config('media.payment_receipts.disk'),
            "payment-receipts/{$order->getKey()}",
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
