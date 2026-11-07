<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «خدمات الموظفين» — صفٌّ لكل موظف وخدمة، وفيه سعرٌ مقترح. Docs/employees/SERVICE-PAY-DESIGN.md §٢.
 *
 * **السعر هنا لا يحدد شيئاً**: يظهر في الحقل على التذكرة، وما يُكتب هناك هو ما يُدفع.
 *
 * **الخدمة نصٌّ لا جدول**: خدمةٌ جديدة حالةٌ في `EmployeeServiceType` ولا migration لها، ويُقرَّر بعدها
 * مكانها وطريقة عرضها. ومَن تُكتب له الخدمة قيدٌ في الكود، لأنه صلاحيةٌ لا يعبّر عنها عمود.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employee_services', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();

            $table->string('service', 30);

            // `NULL` لا سعر — والخدمةُ قائمة، كما يكون الراتب «لم يُحدَّد».
            $table->decimal('suggested_price', 12, 2)->nullable();

            $table->timestamps();
            $table->softDeletes()->index();
        });

        DB::statement(<<<'SQL'
            ALTER TABLE employee_services
            ADD CONSTRAINT employee_services_price_not_negative CHECK (suggested_price >= 0)
        SQL);

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX employee_services_user_service_unique
            ON employee_services (user_id, service)
            WHERE deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_services');
    }
};
