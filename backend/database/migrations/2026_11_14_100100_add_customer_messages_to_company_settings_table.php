<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The four customer messages the staff copy, as the admin wants them worded.
 *
 * **Null means "the built-in text"**, and that is the only default there is: the wording lives
 * in `CustomerMessage::defaultBody()`, not in a column default. A default written here would be
 * a second copy that drifts the first time the code's text is corrected, and a row saved before
 * the correction would keep the old words with nothing to say they were never chosen.
 *
 * `text`, not `string`: a message is a few short paragraphs and the admin decides how many.
 * See Docs/orders/ORDER-RETURN-MESSAGE.md §٥.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('company_settings', function (Blueprint $table) {
            $table->text('ready_pickup_message')->nullable();
            $table->text('ready_delivery_message')->nullable();
            $table->text('return_courier_message')->nullable();
            $table->text('return_carrier_message')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('company_settings', function (Blueprint $table) {
            $table->dropColumn([
                'ready_pickup_message',
                'ready_delivery_message',
                'return_courier_message',
                'return_carrier_message',
            ]);
        });
    }
};
