<?php

use App\Domain\Order\Enums\OrderType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * `orders.order_type` — a normal booking or an instant counter sale (INSTANT-ORDERS-PLAN.md §2).
 *
 * Every existing order is a normal one, which is what the default writes. Indexed because the
 * orders list, the counters and the reports all filter on it.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table): void {
            $table->string('order_type', 20)->default(OrderType::Normal->value)->after('status')->index();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table): void {
            $table->dropIndex(['order_type']);
            $table->dropColumn('order_type');
        });
    }
};
