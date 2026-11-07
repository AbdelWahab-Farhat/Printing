<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * الطلبيات التي تركها الموظف لأن مالها لم يصل بعد. NAWRIS-SETTLEMENT-IMPORT.md §٥.
 *
 * صفرٌ لما سبق، وهذا صحيح: لم يكن أحد يستطيع ترك طلبية.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('nawris_settlement_imports', function (Blueprint $table) {
            $table->unsignedInteger('left_out_count')->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('nawris_settlement_imports', function (Blueprint $table) {
            $table->dropColumn('left_out_count');
        });
    }
};
