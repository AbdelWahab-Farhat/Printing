<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The company, as a participant in its own pools.
 *
 * **Why it is an `investors` row and not a fifth column somewhere.** The company now puts capital
 * into pools beside the investors, and that capital earns a weight exactly as theirs does. Modelled
 * as a special case it would need its own allocation path, its own balance query, its own line on
 * every screen and its own arithmetic in the split — five places to keep in step with the four that
 * already work. As a row it flows through the ledger that already exists and appears in the period
 * share table beside everybody else.
 *
 * **It is paid twice, and that is the design rather than an oversight.** Its capital earns a weight
 * like any partner's; the operator's share — `investor_profit_share_percent`, «50٪ للشركة» — is the
 * residual on top. A single formula then serves a pool the company has money in and one it does
 * not: with no company capital the weight is 100% and the residual is the plain half.
 *
 * At most one such row, by partial unique index. «الشركة» is not a party that can be duplicated,
 * and two of them would split the operator's cut between two accounts with nothing saying which.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investors', function (Blueprint $table) {
            $table->boolean('is_company')->default(false);
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investors_only_one_company
            ON investors (is_company)
            WHERE is_company = true AND deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS investors_only_one_company');

        Schema::table('investors', function (Blueprint $table) {
            $table->dropColumn('is_company');
        });
    }
};
