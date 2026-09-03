<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Nawris — the Libyan last-mile carrier
    |--------------------------------------------------------------------------
    |
    | Credentials are BODY fields on every request, not headers — that is their API, not a
    | choice of ours. Nothing here has a working default: an unset key raises
    | `NawrisIsNotConfigured` before any HTTP call, rather than sending an empty string and
    | relaying whatever they say about it.
    |
    | The constants below are payload defaults that the contract describes as fixed. They live in
    | config rather than in code because they are exactly the values most likely to turn out
    | wrong against the real API — see NAWRIS-INTEGRATION.md §7 on building without a sandbox.
    |
    */
    'nawris' => [
        'base_url' => env('NAWRIS_BASE_URL', 'https://backoffice.nawris.algoriza.com/external-api/'),
        'authentication_key' => env('NAWRIS_AUTHENTICATION_KEY'),
        'main_client_code' => env('NAWRIS_MAIN_CLIENT_CODE'),

        // The shared secret on the inbound webhook, compared in constant time.
        'webhook_secret' => env('NAWRIS_WEBHOOK_SECRET'),

        // Comma-separated. Empty means the allowlist is not enforced — acceptable locally, and
        // the deployment checklist's job everywhere else. The token alone is a thin gate for an
        // endpoint that moves orders and writes money.
        'webhook_ips' => array_values(array_filter(array_map(
            'trim',
            explode(',', (string) env('NAWRIS_WEBHOOK_IPS', '')),
        ))),

        'connect_timeout' => (int) env('NAWRIS_CONNECT_TIMEOUT', 5),
        'timeout' => (int) env('NAWRIS_TIMEOUT', 15),

        // Which `shipping_companies` row a Nawris parcel names, so the existing carrier filters
        // and reports keep working without knowing this integration exists.
        'shipping_company_id' => env('NAWRIS_SHIPPING_COMPANY_ID'),

        'log_channel' => env('NAWRIS_LOG_CHANNEL', 'nawris'),

        // Build the payload, log it, send nothing. The cheapest possible verification against an
        // API nobody has called yet: read the exact JSON before the first live parcel.
        'dry_run' => (bool) env('NAWRIS_DRY_RUN', false),

        'defaults' => [
            // `1` only when the customer may open and inspect before paying. Left off until the
            // business answers; the contract shows it set for locally sourced goods only.
            'can_open' => (int) env('NAWRIS_CAN_OPEN', 0),
            'is_measurable' => (int) env('NAWRIS_IS_MEASURABLE', 0),
            'is_order' => 0,
            'pieces_count' => 1,
            'extra_cost_payer' => 1,
            'is_office_given' => 0,
            'is_fragile' => 0,
            'accept_20_plus_5_dinar' => 0,
        ],

        // Used when a recipient phone is blank, so their validation never refuses a parcel over a
        // field the customer simply never gave us.
        'fallback_phone' => env('NAWRIS_FALLBACK_PHONE', '+218910000000'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

];
