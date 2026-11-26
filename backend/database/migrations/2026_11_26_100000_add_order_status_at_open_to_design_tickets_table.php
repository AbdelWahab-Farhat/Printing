<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The order's status at the moment a ticket was opened on it (owner, 2026-11-26).
 *
 * Approving a ticket moves its order from «قيد التصميم» to «بانتظار التجهيز» only when the ticket
 * was opened while the order was in «قيد التصميم». A ticket opened in «بانتظار العربون» or any
 * other status leaves the order alone, even after the order has reached «قيد التصميم».
 *
 * Nullable with no backfill: a null is a ticket from before this column, or one with no order,
 * and keeps the earlier rule (judged by the order's status at approval).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('design_tickets', function (Blueprint $table) {
            $table->string('order_status_at_open', 32)->nullable()->after('opened_automatically');
        });
    }

    public function down(): void
    {
        Schema::table('design_tickets', function (Blueprint $table) {
            $table->dropColumn('order_status_at_open');
        });
    }
};
