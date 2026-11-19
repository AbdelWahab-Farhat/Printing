<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Whether the system opened the ticket, rather than a person.
 *
 * An order moved into «قيد التصميم» with no open ticket gets one by itself. When the order then
 * leaves for «تجهيز للطباعة» by hand — the customer sent the final file — that ticket is cancelled
 * if no designer has submitted a version yet. A ticket somebody opened on purpose, with a brief
 * they wrote, is never cancelled that way, so the two have to be told apart.
 *
 * Every existing ticket was opened by a person, so the default is the backfill.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('design_tickets', function (Blueprint $table) {
            $table->boolean('opened_automatically')->default(false)->after('order_id');
        });
    }

    public function down(): void
    {
        Schema::table('design_tickets', function (Blueprint $table) {
            $table->dropColumn('opened_automatically');
        });
    }
};
