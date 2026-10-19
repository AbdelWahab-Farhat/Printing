<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * كم يُدفع للطلبية من المحفظة حين يكتمل الشحن — عربون السلة (2026-10-19).
 *
 * فارغٌ في «اشحن وادفع» القديم، فيُدفع ما تستطيعه المحفظة كما كان. ويحمل العربونَ الذي اختاره العميل
 * حين يدفعه إلكترونياً، فلا يُؤخذ من رصيده القديم أكثرُ مما اختار.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payment_intents', function (Blueprint $table): void {
            $table->decimal('order_amount', 12, 2)->nullable()->after('order_id');
        });
    }

    public function down(): void
    {
        Schema::table('payment_intents', function (Blueprint $table): void {
            $table->dropColumn('order_amount');
        });
    }
};
