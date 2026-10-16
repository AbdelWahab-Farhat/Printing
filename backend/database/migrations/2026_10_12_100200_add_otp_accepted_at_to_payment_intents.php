<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * متى قبلت EzonePay رمزَ التحقق — Docs/payments/CUSTOMER-WALLET.md §٨.
 *
 * بعده لا يُطلب رمزٌ ثانٍ: الحساب التجريبي (٢٠٢٦-١٠-١١) أنهى الدفع على الرمز الأول وأجاب الثاني
 * «السجل غير موجود». فيعرض التطبيق «نتحقق من الدفع» ويسأل الخادمُ EzonePay حتى يتّضح.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payment_intents', function (Blueprint $table): void {
            $table->timestamp('otp_accepted_at')->nullable()->after('otp_attempts');
        });
    }

    public function down(): void
    {
        Schema::table('payment_intents', function (Blueprint $table): void {
            $table->dropColumn('otp_accepted_at');
        });
    }
};
