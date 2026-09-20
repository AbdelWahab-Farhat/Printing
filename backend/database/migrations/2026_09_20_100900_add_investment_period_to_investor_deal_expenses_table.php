<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Which period an expense is charged to — decided when it is written, not derived when it is read.
 *
 * **Why `incurred_on` cannot answer this by itself.** A closed period is immutable: its profit has
 * been divided and paid into wallets it can be withdrawn from. So a shipping invoice that arrives
 * in October bearing a September date cannot be charged to September — it goes to the open period
 * instead, keeping its true `incurred_on` and carrying a note that says where it was meant for.
 *
 * Filtering by `incurred_on` at read time would therefore put that invoice back into September
 * every time somebody redrew the screen, and the period's stored snapshot and its live figures
 * would disagree for ever. The period is a decision, so it is recorded as one.
 *
 * Null on a legacy صفقة's expenses, which had no periods at all.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investor_deal_expenses', function (Blueprint $table) {
            $table->foreignId('investment_period_id')->nullable()
                ->constrained('investment_periods')->nullOnDelete();

            $table->index('investment_period_id');
        });
    }

    public function down(): void
    {
        Schema::table('investor_deal_expenses', function (Blueprint $table) {
            $table->dropConstrainedForeignId('investment_period_id');
        });
    }
};
