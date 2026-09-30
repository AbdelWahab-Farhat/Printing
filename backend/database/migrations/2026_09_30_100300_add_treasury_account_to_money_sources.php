<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Where the rest of the company's real money went: a shortage bought for cash, an investor's
 * deposit or withdrawal, an expense paid for the fund. TREASURY-DESIGN §٧.
 *
 * **No CHECK here, unlike `order_payments`.** The actions that write these rows stamp the account
 * every time; what a CHECK would add is refusing rows written *around* the actions — and the only
 * such writers are the investor ledger's own shape tests, which insert raw rows by the dozen to
 * pin arithmetic that has nothing to do with where money sits. Rows from before the treasury stay
 * null here too, counted into the opening balances instead (§١١).
 */
return new class extends Migration
{
    private const TABLES = ['shortage_supplies', 'investor_wallet_entries', 'investor_deal_expenses'];

    public function up(): void
    {
        foreach (self::TABLES as $table) {
            Schema::table($table, function (Blueprint $blueprint) {
                $blueprint->foreignId('treasury_account_id')->nullable()->constrained('treasury_accounts');
            });
        }
    }

    public function down(): void
    {
        foreach (self::TABLES as $table) {
            Schema::table($table, function (Blueprint $blueprint) {
                $blueprint->dropConstrainedForeignId('treasury_account_id');
            });
        }
    }
};
