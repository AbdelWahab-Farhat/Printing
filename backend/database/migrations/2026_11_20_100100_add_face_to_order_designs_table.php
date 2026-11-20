<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Several images under one order design number (DESIGN-VERSION-IMAGES.md §4).
 *
 * A version approved on a ticket with three images lands on the order as «التصميم رقم N» with
 * faces 1–3, approved together. So the two partial indexes widen by one column:
 *
 * - one row per **face** of a version, not per version;
 * - one approved row per **face**, so a whole version can be approved at once. Two approved
 *   versions at the same time stay impossible in practice — `ReviewOrderDesign` rejects every
 *   approved row of any other version before approving — and face 1 still allows only one.
 *
 * Every existing row is face 1, so both indexes accept the data as it stands.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_designs', function (Blueprint $table): void {
            $table->unsignedSmallInteger('face')->default(1)->after('version');
        });

        DB::statement('DROP INDEX IF EXISTS order_designs_unique_version_per_order');
        DB::statement('DROP INDEX IF EXISTS order_designs_one_approved_per_order');

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX order_designs_unique_version_per_order
                ON order_designs (order_id, version, face)
                WHERE deleted_at IS NULL
        SQL);

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX order_designs_one_approved_per_order
                ON order_designs (order_id, face)
                WHERE status = 'approved' AND deleted_at IS NULL
        SQL);
    }

    /**
     * Refuses to run over multi-face data rather than deleting it: the narrower indexes cannot
     * hold two faces of one version, and which face to drop is not a migration's decision.
     */
    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS order_designs_unique_version_per_order');
        DB::statement('DROP INDEX IF EXISTS order_designs_one_approved_per_order');

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX order_designs_unique_version_per_order
                ON order_designs (order_id, version)
                WHERE deleted_at IS NULL
        SQL);

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX order_designs_one_approved_per_order
                ON order_designs (order_id)
                WHERE status = 'approved' AND deleted_at IS NULL
        SQL);

        Schema::table('order_designs', function (Blueprint $table): void {
            $table->dropColumn('face');
        });
    }
};
