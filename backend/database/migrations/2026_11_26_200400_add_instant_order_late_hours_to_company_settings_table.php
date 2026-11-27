<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * How many hours an instant order may sit in «جديدة» before it is flagged «متأخرة»
 * (INSTANT-ORDERS-PLAN.md §4). Default 24, set from the branch settings screen. Nothing is ever
 * cancelled automatically; the flag only makes a forgotten order visible.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('company_settings', function (Blueprint $table): void {
            $table->unsignedSmallInteger('instant_order_late_hours')->default(24);
        });

        DB::statement('ALTER TABLE company_settings ADD CONSTRAINT company_settings_instant_order_late_hours_check CHECK (instant_order_late_hours >= 1)');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE company_settings DROP CONSTRAINT IF EXISTS company_settings_instant_order_late_hours_check');

        Schema::table('company_settings', function (Blueprint $table): void {
            $table->dropColumn('instant_order_late_hours');
        });
    }
};
