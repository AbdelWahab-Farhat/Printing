<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * «متاح للبيع الفوري» — which products the instant-order screen offers (INSTANT-ORDERS-PLAN.md §3).
 *
 * Off for every existing product: the owner switches it on product by product. It is one of the
 * conditions, not the only one — the product must also be plain, priced from its list, and sold
 * in the unit it is stocked in; see InstantSaleEligibility.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table): void {
            $table->boolean('is_instant_sale')->default(false)->after('is_active')->index();
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table): void {
            $table->dropIndex(['is_instant_sale']);
            $table->dropColumn('is_instant_sale');
        });
    }
};
