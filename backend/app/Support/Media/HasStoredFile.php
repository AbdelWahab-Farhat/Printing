<?php

declare(strict_types=1);

namespace App\Support\Media;

use Illuminate\Contracts\Filesystem\Filesystem;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

/**
 * A record that owns a file written by {@see StoreUploadedFile}.
 *
 * Expects `disk` and `path` columns, which is the whole contract. **No URL is ever stored** — a
 * URL embeds a bucket, a region and a host, all of which change, while the disk and the path do
 * not. That is what makes moving to S3 a config change with no migration: rows already written
 * keep resolving from the disk they name.
 *
 * @phpstan-require-extends Model
 */
trait HasStoredFile
{
    public function storage(): Filesystem
    {
        return Storage::disk($this->disk);
    }

    /**
     * Built on demand from the disk this file actually lives on.
     *
     * A disk that signs its URLs — a private S3 bucket, where designs and receipts live —
     * returns a link that expires; a public disk returns a plain one. **Chosen by asking the
     * disk what it supports** rather than by catching a failure: the capability is knowable up
     * front, and a `try`/`catch` here would be the one place in `app/` that has one.
     */
    public function url(): string
    {
        $disk = $this->storage();

        return $disk->providesTemporaryUrls()
            ? $disk->temporaryUrl($this->path, now()->addMinutes(config('media.temporary_url_minutes')))
            : $disk->url($this->path);
    }
}
