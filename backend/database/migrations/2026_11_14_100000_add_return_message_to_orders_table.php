<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «هل تواصلنا مع الزبون بعد أن رجعت طلبيته؟» — the return-side twin of the ready message.
 *
 * Same shape as `ready_message_sent_at/by`, and for the same reasons (see
 * Docs/orders/ORDER-RETURN-MESSAGE.md): a timestamp rather than a boolean, and the person as a
 * column rather than a read of the audit trail.
 *
 * **One difference: these are cleared.** The ready message is sent once in an order's life; a
 * return can happen at the courier, then at the carrier, then again after a resend. Every entry
 * into «راجع لدى المندوب» or «راجع لدى شركة التوصيل» wipes both columns in
 * `ChangeOrderStatus`, so the mark always describes the return the order is in now.
 *
 * No backfill: orders already standing in a return status join the queue, which is correct —
 * nobody recorded contacting those customers (owner's decision, 2026-11-14).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->timestamp('return_message_sent_at')->nullable()->after('returned_at');

            // `nullOnDelete`: an employee leaving does not erase the fact that a message went out.
            $table->foreignId('return_message_sent_by')
                ->nullable()
                ->after('return_message_sent_at')
                ->constrained('users')
                ->nullOnDelete();
        });

        // The queue's own predicate. The status list is the two return statuses that ask for a
        // message — `CustomerMessage::forReturn()`.
        DB::statement(
            'CREATE INDEX orders_return_message_pending_index ON orders (returned_at) '
            ."WHERE return_message_sent_at IS NULL AND status IN ('returned_courier', 'returned_carrier') "
            .'AND deleted_at IS NULL'
        );
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS orders_return_message_pending_index');

        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('return_message_sent_by');
            $table->dropColumn('return_message_sent_at');
        });
    }
};
