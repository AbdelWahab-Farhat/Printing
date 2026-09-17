<?php

declare(strict_types=1);

namespace App\Support\Media;

use App\Domain\Catalog\Actions\UploadProductImage;
use App\Domain\Customer\Actions\UploadCustomerDesign;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

/**
 * Writes an uploaded file to a disk and describes what it wrote.
 *
 * **The one place in the application that puts a user's file on a disk.** Four contexts had
 * grown their own copy of this — {@see UploadProductImage}, {@see UploadCustomerDesign},
 * {@see StoreReceipt}, and design tickets would have been the fourth — and
 * Docs/BACKLOG.md had already recorded that a fourth copy was the wrong answer. The three habits
 * below are security properties, not conveniences, and a property that lives in three places is
 * a property that is true in two of them the day somebody edits one.
 *
 * ## The three guarantees
 *
 * 1. **The type is sniffed from the bytes.** `finfo` reads the magic numbers;
 *    `getClientMimeType()` and the filename's extension are both chosen by whoever uploaded the
 *    file. A JPEG called `waseel.pdf` is recorded as the JPEG it is, and so is a PDF called
 *    `logo.jpg`.
 * 2. **The checksum is taken before the file moves**, while the temporary copy is still
 *    readable. It is what makes an upload idempotent for the callers that want that — a dropped
 *    connection leaves the client unable to know whether the request landed, so a retry has to
 *    be free.
 * 3. **The stored name is generated.** A UUID plus the extension *the bytes* answer to. Two
 *    customers sending `logo.pdf` must not collide, and a client-supplied path is a directory
 *    traversal waiting to be attempted — only the extension survives, and not the one the
 *    client wrote.
 *
 * ## What it deliberately does not do
 *
 * **No validation.** What types are allowed, how large a file may be and how many a record may
 * hold are policy, they differ per context, and they belong in the FormRequest where they
 * produce a readable 422. This action is given a file that has already been judged.
 *
 * **No transaction, and the file is written first.** A failed insert afterwards leaves an
 * orphaned object, which costs storage; the reverse leaves a row pointing at nothing, which is
 * an invoice that cannot show its receipt or an order that cannot show what it printed.
 *
 * **No knowledge of any model.** It takes a disk and a folder and returns a {@see StoredFile};
 * which row that becomes is the caller's business.
 */
final class StoreUploadedFile
{
    /**
     * @param  string  $folder  the directory under the disk root, without a trailing slash
     */
    public function __invoke(UploadedFile $file, string $disk, string $folder): StoredFile
    {
        // Everything measurable is read before the write, while the temporary copy is
        // unambiguously still there and still readable. Reading it afterwards happens to work
        // today — `storeAs` streams the file rather than moving it — but that is an
        // implementation detail of the filesystem driver, and depending on it is how a working
        // upload starts returning a size of zero after a framework upgrade.
        $checksum = hash_file('sha256', (string) $file->getRealPath());
        $mimeType = (string) $file->getMimeType();
        $sizeBytes = (int) $file->getSize();
        $originalFilename = (string) $file->getClientOriginalName();

        [$width, $height] = $this->dimensionsOf($file);

        // `guessExtension()` reads the sniffed type, not the name. The `bin` fallback is
        // unreachable in practice — validation has already limited the answers — and exists so
        // that a null could never write an extensionless path.
        $extension = $file->guessExtension() ?? 'bin';

        $path = (string) $file->storeAs(
            $folder,
            Str::uuid()->toString().'.'.$extension,
            ['disk' => $disk],
        );

        return new StoredFile(
            disk: $disk,
            path: $path,
            originalFilename: $originalFilename,
            mimeType: $mimeType,
            sizeBytes: $sizeBytes,
            checksum: $checksum,
            widthPx: $width,
            heightPx: $height,
        );
    }

    /**
     * Pixels, or nulls for anything that has none.
     *
     * `getimagesize` returns `false` rather than throwing on a file it cannot read as an image —
     * a PDF, a corrupt upload — so a valid upload of a non-image is measured as unmeasurable
     * rather than failing.
     *
     * @return array{0: int|null, 1: int|null}
     */
    private function dimensionsOf(UploadedFile $file): array
    {
        $size = @getimagesize((string) $file->getRealPath());

        return $size === false ? [null, null] : [$size[0], $size[1]];
    }
}
