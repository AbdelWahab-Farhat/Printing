<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Which employees work at which branch (INSTANT-ORDERS-PLAN.md §8–§9).
 *
 * An employee may belong to one branch or several. The link decides the warehouse, the treasury
 * account and which branches the employee may *act* for — it never limits what they may search
 * or read (§9, «آخر تعديل معتمد»).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('branch_user', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('city_id')->constrained('cities')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['city_id', 'user_id']);
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('branch_user');
    }
};
