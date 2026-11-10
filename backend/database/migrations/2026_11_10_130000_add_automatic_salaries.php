<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Automatic salaries — EMPLOYEE-WALLET-DESIGN §١٤.
 *
 * - `treasury_settings.auto_salaries`: the owner's switch, **off** on deploy, so nothing is posted
 *   until somebody turns it on.
 * - `treasury_settings.auto_salaries_from`: the first 1st of a month the run may post on. Written
 *   when the switch goes on (the next month's 1st), so turning it on never pays the current month.
 * - `users.auto_salary`: per employee, on by default. Off keeps that employee on manual entry.
 *
 * No money row changes.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_settings', function (Blueprint $table) {
            $table->boolean('auto_salaries')->default(false)->after('usd_rate');
            $table->date('auto_salaries_from')->nullable()->after('auto_salaries');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->boolean('auto_salary')->default(true)->after('salary');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('auto_salary');
        });

        Schema::table('treasury_settings', function (Blueprint $table) {
            $table->dropColumn(['auto_salaries', 'auto_salaries_from']);
        });
    }
};
