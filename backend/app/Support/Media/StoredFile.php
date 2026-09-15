<?php

declare(strict_types=1);

namespace App\Support\Media;

/**
 * Everything worth recording about a file that has just been written to a disk.
 *
 * Returned by {@see StoreUploadedFile} and consumed by whatever is storing the row. A DTO rather
 * than an associative array for the reason RULES §3 gives for all of them: the three callers
 * here each pick a different subset of these fields, and an array would let one of them misspell
 * a key and write a null into a NOT NULL column at runtime instead of failing to compile.
 *
 * **No URL, and there never will be one.** A URL embeds a bucket, a region and a host, all of
 * which change; the disk and the path do not. Building the link is {@see HasStoredFile::url()}'s
 * job, per request, from the disk the row actually names.
 */
final readonly class StoredFile
{
    public function __construct(
        public string $disk,
        public string $path,
        public string $originalFilename,
        /** Sniffed from the bytes — never the client's claim. See {@see StoreUploadedFile}. */
        public string $mimeType,
        public int $sizeBytes,
        /** sha256 of the contents, taken before the file moved. */
        public string $checksum,
        /** Null for anything that has pages rather than pixels — a PDF, say. */
        public ?int $widthPx,
        public ?int $heightPx,
    ) {}
}
