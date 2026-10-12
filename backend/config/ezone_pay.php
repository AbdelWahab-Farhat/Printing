<?php

/*
 * EzonePay — Docs/payments/CUSTOMER-WALLET.md §٥.
 *
 * **Off until the owner turns it on.** With `enabled` false the server refuses every online top-up
 * and the app hides the button. Built from the shapes Primula's integration runs on; verified
 * against the sandbox with `php artisan ezone:smoke-test` once the credentials are in `.env`.
 */
return [
    'enabled' => (bool) env('EZONE_PAY_ENABLED', false),

    // `fake`: a pretend EzonePay for trying the top-up on an emulator before the sandbox
    // credentials exist — any OTP pays except 0000, and a card link opens a test page on this
    // server. **Ignored in production**, where the real gateway is always bound.
    'driver' => env('EZONE_PAY_DRIVER', 'ezonepay'),

    // The sandbox; the production host is given by EzonePay.
    'base_url' => rtrim((string) env('EZONE_PAY_BASE_URL', 'https://test.ezonepay.ly'), '/'),

    'email' => env('EZONE_PAY_EMAIL'),
    'password' => env('EZONE_PAY_PASSWORD'),

    // Sent as `shopId` when set. Empty: left out, and EzonePay uses the merchant's default shop.
    'shop_id' => is_numeric(env('EZONE_PAY_SHOP_ID')) ? (int) env('EZONE_PAY_SHOP_ID') : null,

    // The `SecretKey` `/Webhook/subscribe` returns — used as-is, not base64-decoded. Empty:
    // every webhook is refused (fail closed).
    'webhook_secret' => env('EZONE_PAY_WEBHOOK_SECRET'),

    'connect_timeout' => (int) env('EZONE_PAY_CONNECT_TIMEOUT', 3),
    'timeout' => (int) env('EZONE_PAY_TIMEOUT', 12),

    // Renew the access token this long before EzonePay says it expires.
    'token_buffer_seconds' => 60,

    // A method's fee rate, quoted once at a reference amount, lives this long.
    'rate_cache_seconds' => 8 * 3600,

    // EzonePay's quote for one amount — the screen's, kept so the start charges the same.
    'quote_cache_seconds' => 900,

    // A quote that failed is remembered this long — the method is hidden meanwhile.
    'rate_failure_seconds' => 60,

    'otp_max_attempts' => (int) env('EZONE_PAY_OTP_MAX_ATTEMPTS', 3),

    // An OTP or QR attempt nobody finished, and a card link nobody paid.
    'intent_ttl_minutes' => 30,
    'link_ttl_minutes' => 60,

    // A card link past its end is asked about this much longer before it is given up on — a
    // payment made in its last minute reaches EzonePay's list first.
    'link_grace_minutes' => 15,

    // `payments:reconcile` asks EzonePay about a pending intent this old.
    'reconcile_after_minutes' => 10,

    // A recent pending intent counts against the limits — two quick top-ups cannot pass a cap.
    'pending_counts_minutes' => 30,

    // Where the hosted card page sends the customer back to; null lets EzonePay decide.
    'redirect_url' => env('EZONE_PAY_REDIRECT_URL'),
];
