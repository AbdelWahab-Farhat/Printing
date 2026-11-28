<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Branch settings on the office-pickup cities (INSTANT-ORDERS-PLAN.md §8).
 *
 * A city whose fulfilment type is «استلام مكتب» already *is* a branch, and already has its cash
 * box (`treasury_accounts.pickup_city_id`). These columns add the rest of what an instant sale
 * needs from it:
 *
 * - `is_branch_active` — off stops new instant orders there; past orders are untouched.
 * - `default_warehouse_id` — where an instant order's stock comes from. Copied onto the order
 *   (`fulfillment_warehouse_id`) at creation, so changing it never rewrites history.
 * - `bank_transfer_account_id`, `bank_card_account_id` — where a transfer or a card payment taken
 *   at this branch lands. Cash keeps using the existing branch box.
 *
 * All nullable and null on delete: a branch that is not configured refuses the affected action
 * with a clear message rather than guessing (§8).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cities', function (Blueprint $table): void {
            $table->boolean('is_branch_active')->default(true)->after('fulfilment_type');
            $table->foreignId('default_warehouse_id')->nullable()->after('is_branch_active')
                ->constrained('warehouses')->nullOnDelete();
            $table->foreignId('bank_transfer_account_id')->nullable()->after('default_warehouse_id')
                ->constrained('treasury_accounts')->nullOnDelete();
            $table->foreignId('bank_card_account_id')->nullable()->after('bank_transfer_account_id')
                ->constrained('treasury_accounts')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('cities', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('bank_card_account_id');
            $table->dropConstrainedForeignId('bank_transfer_account_id');
            $table->dropConstrainedForeignId('default_warehouse_id');
            $table->dropColumn('is_branch_active');
        });
    }
};
