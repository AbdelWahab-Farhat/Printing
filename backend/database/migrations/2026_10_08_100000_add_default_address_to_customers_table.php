<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * عنوان العميل — the place an order goes when nobody says otherwise.
 *
 * Staff were picking the same city and neighbourhood by hand on every order for the same
 * customer. A shop already carries a place, but plenty of customers sell from one place and name
 * no shop at all, so the default lives on the customer itself and the order form starts from it.
 *
 * **A default, not a fact about any order.** Orders copy `city_name` and `region_name` at the
 * moment they are taken, so changing this never rewrites where an old order said it was going.
 *
 * **Both nullable, and no backfill.** Every customer on record today has no address, and there is
 * no honest source to invent one from — the first shop's city would be a guess presented as a
 * fact. The region stays optional for the same reason it is optional on a shop: most cities have
 * none, and `is_region_required` is a delivery rule the order answers, not the customer.
 *
 * **`nullOnDelete` on both.** Unlike a shop's city, which is the whole point of the row, losing a
 * default only means the next order starts empty — the outcome there was before this column.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->foreignId('city_id')->nullable()->after('phone')->constrained()->nullOnDelete();
            $table->foreignId('region_id')->nullable()->after('city_id')->constrained()->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->dropConstrainedForeignId('region_id');
            $table->dropConstrainedForeignId('city_id');
        });
    }
};
