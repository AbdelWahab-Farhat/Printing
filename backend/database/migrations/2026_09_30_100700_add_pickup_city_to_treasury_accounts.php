<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «خزنة مكتب الاستلام» — the cash box of each branch a customer collects from. Cash taken while
 * an order waits at «استلام مكتب» lands there when nobody picks. TREASURY-DESIGN §١٩.
 *
 * The branch *is* a city row marked `office_pickup` — the delivery map already knows it — so the
 * box names the city rather than a branch table nobody has. Null on every account today, so
 * running this changes nothing until a box is linked.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_accounts', function (Blueprint $table) {
            $table->foreignId('pickup_city_id')->nullable()->after('is_collected')
                ->constrained('cities');
        });

        // A branch's cash is cash: a bank account cannot sit at a counter.
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_pickup_city_cash
            CHECK (pickup_city_id IS NULL OR kind = 'cash')");

        // One box per branch, or «تلقائي» would have two answers.
        DB::statement('CREATE UNIQUE INDEX treasury_accounts_one_box_per_office
            ON treasury_accounts (pickup_city_id)
            WHERE pickup_city_id IS NOT NULL AND deleted_at IS NULL');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS treasury_accounts_one_box_per_office');
        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT IF EXISTS treasury_accounts_pickup_city_cash');

        Schema::table('treasury_accounts', function (Blueprint $table) {
            $table->dropConstrainedForeignId('pickup_city_id');
        });
    }
};
