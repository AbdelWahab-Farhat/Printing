<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Whether a person decided an order's «أجرة التصميم». See Docs/orders/ORDER-DESIGN-FEE.md.
 *
 * Null means nobody did: approving one of the order's design tickets may then fill the fee from
 * «أجرة المصمم». Set, it is a decision, including a decision to charge nothing, and no ticket
 * touches it again.
 *
 * **Every order that already carries a fee is backfilled as decided**, by the clerk who took it and
 * when they took it. That fee was typed on purpose, before the box left the new-order form; letting
 * the next approval overwrite it with a designer's pay would rewrite an agreed price.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->timestamp('design_fee_set_at')->nullable()->after('design_fee');
            $table->foreignId('design_fee_set_by')
                ->nullable()
                ->after('design_fee_set_at')
                ->constrained('users')
                ->nullOnDelete();
        });

        DB::table('orders')
            ->where('design_fee', '>', 0)
            ->update([
                'design_fee_set_at' => DB::raw('created_at'),
                'design_fee_set_by' => DB::raw('created_by'),
            ]);
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['design_fee_set_by']);
            $table->dropColumn(['design_fee_set_at', 'design_fee_set_by']);
        });
    }
};
