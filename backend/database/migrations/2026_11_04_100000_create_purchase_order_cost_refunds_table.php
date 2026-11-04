<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «استرداد التكلفة» — Docs/purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md §7.
 *
 * One row per refund of a cost paid from a drawer or owed to a manual payable. The money itself
 * is the cost's `expense` movement, reposted at what is left; this row is the why and the who.
 * `reversed_at` set means the refund was itself a mistake and no longer counts.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('purchase_order_cost_refunds', function (Blueprint $table) {
            $table->id();
            $table->foreignId('additional_cost_id')->constrained('purchase_order_additional_costs');
            $table->decimal('amount', 14, 2);
            $table->string('reason', 500);
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reversed_at')->nullable();
            $table->foreignId('reversed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('reversal_reason', 500)->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        DB::statement('ALTER TABLE purchase_order_cost_refunds
            ADD CONSTRAINT purchase_order_cost_refunds_amount_positive
            CHECK (amount > 0)');
    }

    public function down(): void
    {
        Schema::dropIfExists('purchase_order_cost_refunds');
    }
};
