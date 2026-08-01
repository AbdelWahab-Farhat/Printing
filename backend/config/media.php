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

    /*
    |--------------------------------------------------------------------------
    | Customer design constraints
    |--------------------------------------------------------------------------
    |
    | A customer's artwork — the image or PDF printed on their bags.
    |
    | **A different disk from product images, deliberately.** A product photo is the
    | business's own marketing and belongs on a public disk. A design is the customer's
    | property, and the `public` disk hands out permanent unauthenticated URLs — one leaked
    | path is a competitor holding somebody's print file. `local` is storage/app/private;
    | production points this at S3 with private visibility, and the signed-URL lifetime
    | above then applies.
    |
    | One size limit for both kinds, not two. Every limit here is mirrored as a pre-flight
    | check in the app, so a second number is a third place that has to agree.
    |
    | `svg` is absent on purpose and must stay absent: an SVG is an HTML document, and one
    | served from our own origin is stored XSS.
    |
    */

    'customer_designs' => [
        'disk' => env('MEDIA_DESIGNS_DISK', 'local'),
        'max_kilobytes' => (int) env('MEDIA_DESIGN_MAX_KILOBYTES', 25600),
        'mimes' => ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        'mimetypes' => ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'],
        'max_per_customer' => (int) env('MEDIA_DESIGNS_MAX_PER_CUSTOMER', 50),
    ],

    'product_images' => [
        'max_kilobytes' => (int) env('MEDIA_MAX_KILOBYTES', 5120),
        'mimes' => ['jpeg', 'jpg', 'png', 'webp'],
    ],

];
