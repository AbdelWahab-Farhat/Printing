<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «رسالة المندوب» — the courier's number, copied to the customer.
 *
 * `company_settings.courier_contact_message` is the admin's wording; null means the built-in text
 * in `CustomerMessage::defaultBody()`, exactly as for the other messages.
 *
 * **The backfill.** Nawris names the courier on «مع المندوب» (code 4), and until this change the
 * number was saved only when the event also moved the order's status — which code 4 almost never
 * does. The events were all stored, so the number is recovered from them: the latest
 * `captain_phone` of each parcel, onto its orders that have none. A number already on an order —
 * a later event's, or one typed at dispatch — is left alone. Written straight to the table, so it
 * leaves no audit line; it restores what the webhook should have written at the time.
 * See Docs/nawris/NAWRIS-INTEGRATION.md §5.5.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('company_settings', function (Blueprint $table) {
            $table->text('courier_contact_message')->nullable();
        });

        $this->backfillCourierPhones();
    }

    public function down(): void
    {
        // The recovered numbers stay: they are what the webhook should have written.
        Schema::table('company_settings', function (Blueprint $table) {
            $table->dropColumn('courier_contact_message');
        });
    }

    private function backfillCourierPhones(): void
    {
        /** @var array<int, string> $latest parcel id => the last courier phone it was sent */
        $latest = [];

        DB::table('nawris_webhook_events')
            ->whereNotNull('nawris_parcel_id')
            ->select(['id', 'nawris_parcel_id', 'payload'])
            ->chunkById(500, function ($events) use (&$latest): void {
                foreach ($events as $event) {
                    $payload = is_string($event->payload) ? json_decode($event->payload, true) : (array) $event->payload;
                    $phone = is_array($payload) && is_scalar($payload['captain_phone'] ?? null)
                        ? trim((string) $payload['captain_phone'])
                        : '';

                    // The column holds 20 characters; anything longer is not a phone number.
                    if ($phone !== '' && mb_strlen($phone) <= 20) {
                        $latest[(int) $event->nawris_parcel_id] = $phone;
                    }
                }
            });

        foreach ($latest as $parcelId => $phone) {
            // Live links only: an order unlinked from a parcel was never carried by its courier.
            $orderIds = DB::table('nawris_parcel_orders')
                ->where('nawris_parcel_id', $parcelId)
                ->whereNull('deleted_at')
                ->select('order_id');

            DB::table('orders')
                ->whereIn('id', $orderIds)
                ->where(fn ($query) => $query->whereNull('courier_phone')->orWhere('courier_phone', ''))
                ->update(['courier_phone' => $phone]);
        }
    }
};
