<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * «رسالة المورد» — the text staff copy and send to the vendor of an outsourced order, and the
 * switch that records it was sent.
 *
 * `orders.vendor_message_sent_at/by` take the shape of `ready_message_sent_at/by`: a timestamp
 * rather than a boolean, and the person as a column rather than a read of the audit trail. They
 * are cleared on every entry into «قيد التصميم», because a design correction means the vendor
 * has to be sent the job again.
 *
 * `company_settings.vendor_request_message` is the admin's wording; null means the built-in
 * text in `CustomerMessage::defaultBody()`, exactly as for the four customer messages.
 *
 * No backfill: nobody recorded sending a message for orders already with a vendor.
 * See Docs/outsourced-products/OUTSOURCED-PRODUCTS.md §10.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->timestamp('vendor_message_sent_at')->nullable()->after('manufacturing_started_at');

            // `nullOnDelete`: an employee leaving does not erase the fact that a message went out.
            $table->foreignId('vendor_message_sent_by')
                ->nullable()
                ->after('vendor_message_sent_at')
                ->constrained('users')
                ->nullOnDelete();
        });

        Schema::table('company_settings', function (Blueprint $table) {
            $table->text('vendor_request_message')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('company_settings', function (Blueprint $table) {
            $table->dropColumn('vendor_request_message');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('vendor_message_sent_by');
            $table->dropColumn('vendor_message_sent_at');
        });
    }
};
