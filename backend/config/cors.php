<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | The framework's default, with one path added: `storage/*`.
    |
    | The staff app's web build (staff.daaya.ly) draws images on a canvas, and the
    | browser only lets it do that with a file from another origin when the response
    | carries Access-Control-Allow-Origin. Private files — designs, receipts,
    | attachments — are signed links Laravel serves from `storage/{path}` (the `local`
    | disk's `serve`), so the header has to come from here. Public files under
    | /storage/ are served by nginx directly and get the header there.
    |
    | See Docs/web/STAFF-WEB.md §5.3.
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie', 'storage/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => ['*'],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
