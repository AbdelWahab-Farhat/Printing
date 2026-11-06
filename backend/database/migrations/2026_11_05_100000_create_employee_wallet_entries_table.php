<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «محفظة الموظف» — دفترٌ يُضاف إليه ولا يُعدَّل، لكل موظف. Docs/employees/EMPLOYEE-WALLET-DESIGN.md §٨.
 *
 * على نسق `customer_wallet_entries`: مبلغٌ موجبٌ دائماً والاتجاهُ من النوع، والخطأ سطرٌ ثانٍ يشير إلى
 * أصله، ولا عمودَ رصيدٍ في أيّ مكان. **المحفظة هي الموظف**، فلا جدولَ محافظ يُحفظ في تزامنٍ مع
 * `users`.
 *
 * **والفرق عن الزبون أن السحب مسموح**، وأن الدَّين لا يدخلها: الرصيد لا ينزل تحت الصفر، والسلفة تبقى
 * مصروفاً كما هي (قرار صاحب العمل ٢٠٢٦-١١-٠٥، §٩ س٤).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employee_wallet_entries', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();

            $table->string('type', 30);

            $table->decimal('amount', 14, 2);

            // كيف دخل المال أو خرج — للإيداع والسحب وحدهما؛ ما سواهما لا يمرّ بحساب.
            $table->string('method', 20)->nullable();

            // الحساب الذي وصله المال أو خرج منه. «أرصدة محافظ الموظفين» لا تُسمّى هنا: كلُّ سطرٍ
            // يحرّكها، فتسميتُها لا تقول شيئاً.
            $table->foreignId('treasury_account_id')->nullable()
                ->constrained('treasury_accounts')->restrictOnDelete();

            // المستحق وحده: تصنيفُه، والعمليةُ التي كتبته مصروفاً. والعكسُ يعكسها من هذا السطر.
            $table->foreignId('expense_category_id')->nullable()
                ->constrained('treasury_expense_categories')->restrictOnDelete();
            $table->foreignId('treasury_operation_id')->nullable()
                ->constrained('treasury_operations')->restrictOnDelete();

            $table->string('reference', 100)->nullable();

            // الواصل — إجباريٌّ للحوالة في الاتجاهين، بالأعمدة الخمسة نفسها وبـ`StoreReceipt` نفسه.
            $table->string('receipt_disk', 50)->nullable();
            $table->string('receipt_path')->nullable();
            $table->string('receipt_original_filename')->nullable();
            $table->unsignedBigInteger('receipt_size_bytes')->nullable();
            $table->string('receipt_checksum', 64)->nullable();

            // متى تحرّك المال، لا متى كُتب.
            $table->timestamp('occurred_at');

            $table->text('notes')->nullable();

            $table->foreignId('reverses_entry_id')->nullable()
                ->constrained('employee_wallet_entries')->restrictOnDelete();

            // رمزٌ يولّده التطبيق قبل الإرسال — فلا تكتب الضغطةُ الثانية سطراً ثانياً.
            $table->string('client_token', 64)->nullable();

            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            // موجودٌ لأن كل نموذج يحذف حذفاً ناعماً؛ والنموذج نفسه يرفض استعماله.
            $table->softDeletes()->index();

            $table->index(['user_id', 'id']);
            $table->index(['type', 'occurred_at']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE employee_wallet_entries
            ADD CONSTRAINT employee_wallet_entries_amount_positive CHECK (amount > 0)
        SQL);

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX employee_wallet_entries_reversed_once
            ON employee_wallet_entries (reverses_entry_id)
            WHERE reverses_entry_id IS NOT NULL AND deleted_at IS NULL
        SQL);

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX employee_wallet_entries_client_token_unique
            ON employee_wallet_entries (user_id, client_token)
            WHERE client_token IS NOT NULL AND deleted_at IS NULL
        SQL);

        // المستحقُّ سطرٌ واحد لعمليةٍ واحدة، وعكسُه يشير إليه لا إليها.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX employee_wallet_entries_one_per_operation
            ON employee_wallet_entries (treasury_operation_id)
            WHERE treasury_operation_id IS NOT NULL AND deleted_at IS NULL
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE employee_wallet_entries
            ADD CONSTRAINT employee_wallet_entries_transfer_needs_receipt CHECK (
                method IS DISTINCT FROM 'bank_transfer' OR receipt_path IS NOT NULL
            )
        SQL);

        // الأشكال الموجودة، وكلٌّ يقول ما يحمله.
        DB::statement(<<<'SQL'
            ALTER TABLE employee_wallet_entries
            ADD CONSTRAINT employee_wallet_entries_shape CHECK (
                (type IN ('deposit', 'withdrawal')
                    AND method IS NOT NULL AND treasury_account_id IS NOT NULL
                    AND expense_category_id IS NULL AND treasury_operation_id IS NULL
                    AND reverses_entry_id IS NULL)
                OR (type = 'credit'
                    AND method IS NULL AND treasury_account_id IS NULL
                    AND expense_category_id IS NOT NULL AND treasury_operation_id IS NOT NULL
                    AND reverses_entry_id IS NULL)
                OR (type IN ('adjustment_credit', 'adjustment_debit')
                    AND method IS NULL AND treasury_account_id IS NULL
                    AND expense_category_id IS NULL AND treasury_operation_id IS NULL
                    AND reverses_entry_id IS NULL AND notes IS NOT NULL)
                OR (type = 'reversal'
                    AND method IS NULL AND treasury_account_id IS NULL
                    AND expense_category_id IS NULL AND treasury_operation_id IS NULL
                    AND reverses_entry_id IS NOT NULL AND notes IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_wallet_entries');
    }
};
