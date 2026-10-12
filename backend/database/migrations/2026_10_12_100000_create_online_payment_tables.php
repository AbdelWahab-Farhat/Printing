<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * الشحن الإلكتروني عبر EzonePay — Docs/payments/CUSTOMER-WALLET.md §٥ (الخطوات ٤–٦).
 *
 * **حسابُ «Ezone»** في الحسابات: ما جمعه EzonePay لنا ولم يحوّله إلى المصرف بعد. كل طرق الدفع
 * الإلكتروني تهبط فيه، والطريقةُ محفوظةٌ على محاولة الدفع.
 *
 * **تصنيفُ «عمولة الدفع الإلكتروني»**: ما أخذه EzonePay من كل شحنٍ مصروفٌ يُرى في «المصاريف»، أيّاً
 * كان من يتحمّلها.
 *
 * **`online_fee_payer`** في «إعدادات المالية»: الزبونُ (الافتراض — قرار صاحب العمل ٢٠٢٦-١٠-١١) أو
 * المحلّ.
 *
 * **`online_payment_methods`**: كل طريقةٍ تُفعَّل أو تُعطَّل، وحدودُها اليومية والشهرية والسنوية.
 *
 * **`payment_intents`**: محاولةُ دفعٍ واحدة. مرجعُها يولّده الخادم، ورقمُ معاملة EzonePay فريد،
 * وصفُّ المحفظة الذي شحنته فريد — **يُشحن مرّةً واحدة بقيدٍ في القاعدة**.
 *
 * **`gateway_webhook_events`**: كل ما وصل من EzonePay، مرّةً واحدة بمفتاحٍ فريد.
 */
return new class extends Migration
{
    public function up(): void
    {
        $now = now();

        DB::table('treasury_accounts')->insert([
            'name' => 'Ezone',
            'kind' => 'wallet',
            'system_code' => 'ezone',
            'is_default' => false,
            'currency' => 'LYD',
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('treasury_expense_categories')->insert([
            'name' => 'عمولة الدفع الإلكتروني',
            'code' => 'online_payment_fee',
            'requires_employee' => false,
            'is_active' => true,
            'sort_order' => 2,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        Schema::table('treasury_settings', function (Blueprint $table) {
            // «العمولة على»: `customer` — يُخصم منه المبلغُ وعمولته؛ `shop` — يُخصم المبلغ وحده.
            $table->string('online_fee_payer', 10)->default('customer');
        });

        DB::statement(<<<'SQL'
            ALTER TABLE treasury_settings
            ADD CONSTRAINT treasury_settings_online_fee_payer CHECK (online_fee_payer IN ('customer', 'shop'))
        SQL);

        Schema::create('online_payment_methods', function (Blueprint $table) {
            $table->id();
            $table->string('gateway', 24)->default('ezone');

            // رقمُ الطريقة عند EzonePay — 111 ليبيانا، 101 بطاقات مُعاملات…
            $table->unsignedSmallInteger('method');

            $table->boolean('is_active')->default(true);

            // سقفُ ما يُشحن بالطريقة، صافياً، لكل زبون. فارغٌ: بلا سقف.
            $table->decimal('daily_limit', 14, 2)->nullable();
            $table->decimal('monthly_limit', 14, 2)->nullable();
            $table->decimal('yearly_limit', 14, 2)->nullable();

            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['gateway', 'method']);
        });

        $methods = [101, 102, 103, 104, 105, 106, 107, 108, 111, 123, 124, 125, 128];

        foreach ($methods as $method) {
            DB::table('online_payment_methods')->insert([
                'gateway' => 'ezone',
                'method' => $method,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        Schema::create('payment_intents', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('gateway', 24)->default('ezone');

            $table->foreignId('customer_id')->constrained('customers')->restrictOnDelete();

            // «اشحن وادفع»: الطلبيةُ التي تُدفع من المحفظة بعد أن تُشحن. فارغٌ لشحنٍ وحده.
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();

            $table->unsignedSmallInteger('method');
            $table->string('flow', 8);

            // ما طلب الزبون أن يصل محفظته، ونسبةُ العمولة ساعةَ البدء، وما يُخصم منه فعلاً.
            $table->decimal('net_amount', 14, 2);
            $table->decimal('fee_rate', 10, 6);
            $table->string('fee_payer', 10);
            $table->decimal('gross_amount', 14, 2);

            // ما أخذه EzonePay فعلاً، حين يُعرف.
            $table->decimal('provider_fee', 14, 2)->nullable();

            $table->string('status', 16)->default('created');

            // **يولّده الخادم** ويُرسل `orderReference` — به يُطابَق الـ webhook بلا تخمين.
            $table->string('our_reference', 64)->unique();
            $table->unsignedBigInteger('provider_transaction_id')->nullable()->unique();
            $table->unsignedBigInteger('provider_link_id')->nullable()->unique();
            $table->string('payment_url', 500)->nullable();

            $table->unsignedSmallInteger('otp_attempts')->default(0);

            $table->json('customer_info')->nullable();
            $table->json('provider_response')->nullable();
            $table->string('failure_reason', 255)->nullable();

            // **فريد**: المحاولةُ تشحن المحفظة مرّةً واحدة، تقولها القاعدة لا الكود وحده.
            $table->foreignId('wallet_entry_id')->nullable()->unique()
                ->constrained('customer_wallet_entries')->restrictOnDelete();

            // رمزُ الإرسال من التطبيق: الضغطةُ الثانية تعود بالمحاولة الأولى.
            $table->string('client_token', 64)->nullable();

            $table->timestamp('expires_at')->nullable();
            $table->timestamp('succeeded_at')->nullable();
            $table->timestamp('failed_at')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->index(['customer_id', 'status', 'created_at']);
            $table->index(['gateway', 'status', 'created_at']);
            $table->unique(['customer_id', 'client_token']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE payment_intents
            ADD CONSTRAINT payment_intents_amounts_positive CHECK (
                net_amount > 0 AND gross_amount >= net_amount AND fee_rate >= 0
            )
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE payment_intents
            ADD CONSTRAINT payment_intents_status CHECK (
                status IN ('created', 'pending', 'succeeded', 'failed', 'expired', 'needs_review')
            )
        SQL);

        Schema::create('gateway_webhook_events', function (Blueprint $table) {
            $table->id();
            $table->string('gateway', 24);

            // sha256 الجسم الخام — الحدثُ نفسه مرّتين مفتاحٌ واحد.
            $table->string('event_key', 191);

            $table->json('payload');
            $table->string('status', 16)->default('received');
            $table->unsignedSmallInteger('attempts')->default(0);
            $table->text('error')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->unique(['gateway', 'event_key']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gateway_webhook_events');
        Schema::dropIfExists('payment_intents');
        Schema::dropIfExists('online_payment_methods');

        DB::statement('ALTER TABLE treasury_settings DROP CONSTRAINT IF EXISTS treasury_settings_online_fee_payer');

        Schema::table('treasury_settings', function (Blueprint $table) {
            $table->dropColumn('online_fee_payer');
        });

        DB::table('treasury_expense_categories')->where('code', 'online_payment_fee')->delete();
        DB::table('treasury_accounts')->where('system_code', 'ezone')->delete();
    }
};
