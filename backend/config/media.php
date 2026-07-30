<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Media disk
    |--------------------------------------------------------------------------
    |
    | Where newly uploaded product images are written. Local development uses the
    | `public` disk; production will set MEDIA_DISK=s3.
    |
    | Moving to S3 is three steps and no code change:
    |   1. composer require league/flysystem-aws-s3-v3
    |   2. set AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_DEFAULT_REGION / AWS_BUCKET
    |   3. set MEDIA_DISK=s3
    |
    | Each image row records the disk it was written to, so flipping this value only
    | affects *new* uploads. Images already on the old disk keep resolving from it, which
    | means the switch needs no migration and no downtime.
    |
    */

    'disk' => env('MEDIA_DISK', 'public'),

    /*
    |--------------------------------------------------------------------------
    | Temporary URL lifetime
    |--------------------------------------------------------------------------
    |
    | Used only by disks that sign their URLs, such as a private S3 bucket. Public
    | disks ignore it and return a plain permanent URL.
    |
    */

    'temporary_url_minutes' => (int) env('MEDIA_TEMPORARY_URL_MINUTES', 60),

    /*
    |--------------------------------------------------------------------------
    | Product image constraints
    |--------------------------------------------------------------------------
    */

    'product_images' => [
        'max_kilobytes' => (int) env('MEDIA_MAX_KILOBYTES', 5120),
        'mimes' => ['jpeg', 'jpg', 'png', 'webp'],
    ],

];
