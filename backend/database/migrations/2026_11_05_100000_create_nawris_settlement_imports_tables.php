<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * تسوية طلبيات النورس بملف إكسل — Docs/nawris/NAWRIS-SETTLEMENT-IMPORT.md.
 *
 * الدفعة تُسوّي مئات الطلبيات بضغطة واحدة وتحرّك مالها، فكل رفعة تُحفظ بأسطرها كاملة: ما سُوّي وما
 * تُخطّي ولماذا، بالقيم كما وردت في الملف — الملف نفسه لا يُحفظ، وقد يُعدَّل أو يضيع.
 *
 * **`client_token` فريدٌ في قاعدة البيانات لا في الكود وحده**: ضغطتان على «تنفيذ» تصلان معاً تمرّان
 * من أي فحص، والفهرس وحده يوقف الثانية. جزئيٌّ كسائر الفهارس الفريدة هنا (RULES §١٠).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nawris_settlement_imports', function (Blueprint $table) {
            $table->id();
            $table->string('file_name');
            $table->uuid('client_token');
            $table->foreignId('imported_by')->constrained('users');

            $table->unsignedInteger('rows_count');
            $table->unsignedInteger('orders_count');
            $table->unsignedInteger('settled_count');
            $table->unsignedInteger('skipped_count');
            $table->unsignedInteger('rejected_count');
            $table->unsignedInteger('warnings_count');

            // ما كان عند النورس لهذه الطلبيات، وما وصل فعلاً، والفرق الذي احتفظ به.
            $table->decimal('total_held', 14, 2);
            $table->decimal('received_amount', 14, 2);
            $table->decimal('fee_total', 14, 2);
            $table->string('difference_reason', 500)->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['imported_by', 'created_at']);
        });

        DB::statement(
            'CREATE UNIQUE INDEX nawris_settlement_imports_client_token_unique '
            .'ON nawris_settlement_imports (client_token) WHERE deleted_at IS NULL'
        );

        Schema::create('nawris_settlement_import_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('nawris_settlement_import_id')->constrained('nawris_settlement_imports');

            $table->unsignedInteger('row_number');
            $table->string('raw_status')->nullable();
            $table->string('raw_code')->nullable();
            $table->string('raw_receiver')->nullable();

            // فارغان حين لا يُعرف السطر بأي طلبية.
            $table->foreignId('order_id')->nullable()->constrained('orders');
            $table->string('order_code')->nullable();
            $table->string('previous_status', 50)->nullable();

            $table->string('outcome', 30);
            $table->string('reason_code', 50)->nullable();
            $table->string('reason')->nullable();
            $table->json('warnings')->nullable();

            $table->decimal('held_amount', 14, 2);
            $table->decimal('fee_amount', 14, 2);

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index('order_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nawris_settlement_import_items');
        Schema::dropIfExists('nawris_settlement_imports');
    }
};
