<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * When an archived order took its stock off the shelf a second time — see `RestoreOrder`.
 *
 * **What it guards.** An order's lines can now be edited after the stock has left
 * (Docs/orders/ORDER-LINES-ADD-REMOVE.md §6), and the edit re-posts the investors' purchase per
 * line. On a restored order that re-post would read the first draw's settled payment as a figure
 * to correct — the open BACKLOG item «الاستعادة ثم إعادة بيان الخصم» — so `SyncOrderItems` refuses
 * to move stock on an order carrying this stamp.
 *
 * **Why a column and not the ledger.** A restore is a reversal followed by a draw, and so is every
 * line edit after the stock left: the two leave the same shape of movements behind and only the
 * order can say which one happened.
 *
 * **Backfilled from the audit trail**, which has recorded every restore as a `restored` event on
 * the order since the archive existed. Only orders whose stock had left are stamped; a restore of
 * anything else drew nothing a second time.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->timestamp('stock_redrawn_at')->nullable()->after('delete_returned_stock_at');
        });

        DB::statement(<<<'SQL'
            UPDATE orders
               SET stock_redrawn_at = restores.restored_at
              FROM (
                    SELECT subject_id, MAX(created_at) AS restored_at
                      FROM activity_log
                     WHERE subject_type = 'order'
                       AND event = 'restored'
                  GROUP BY subject_id
                   ) AS restores
             WHERE restores.subject_id = orders.id
               AND orders.stock_deducted_at IS NOT NULL
        SQL);
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('stock_redrawn_at');
        });
    }
};
