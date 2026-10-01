<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * الحسابات والخزائن — the four tables, and the accounts nothing can work without.
 *
 * **No balance column anywhere.** A balance is the sum of an account's movements, the same bargain
 * `order_payments` and `stock_movements` strike: a figure somebody can overwrite explains nothing.
 *
 * **The default accounts are seeded here, not in a seeder**, because every money path falls back
 * to them when the app sends no account — which today's app never does. Seeded in the migration,
 * they exist in production the moment the code that needs them does, and in every test database
 * that `RefreshDatabase` builds. See TREASURY-DESIGN §٢, «لا يتعطّل شيء قائم».
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('treasury_accounts', function (Blueprint $table) {
            $table->id();

            $table->string('name', 100);

            // cash · bank · wallet · custody — see AccountKind.
            $table->string('kind', 20);

            // «مصرف علي»: the account is the company's, the name on it is his. Null for the
            // company's own drawers.
            $table->foreignId('holder_user_id')->nullable()->constrained('users')->nullOnDelete();

            // How code finds an account it depends on without trusting a name somebody can edit.
            // `nawris` alone today — the webhook's destination.
            $table->string('system_code', 30)->nullable();

            // The account a method falls back to when nobody chose one — one per kind.
            $table->boolean('is_default')->default(false);

            // Dinars only, said by the schema rather than assumed by the code. The day dollars
            // come, this CHECK is widened and a rate goes on the transfer — no column to add.
            $table->char('currency', 3)->default('LYD');

            $table->boolean('is_active')->default(true);
            $table->text('notes')->nullable();

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();
        });

        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_kind_check
            CHECK (kind IN ('cash', 'bank', 'wallet', 'custody'))");

        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_currency_check
            CHECK (currency = 'LYD')");

        // Custody is where money waits to be handed over; nothing should *fall back* into it.
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_default_shape
            CHECK (NOT is_default OR (kind <> 'custody' AND is_active))");

        DB::statement('CREATE UNIQUE INDEX treasury_accounts_default_per_kind
            ON treasury_accounts (kind) WHERE is_default AND deleted_at IS NULL');

        DB::statement('CREATE UNIQUE INDEX treasury_accounts_system_code_unique
            ON treasury_accounts (system_code) WHERE system_code IS NOT NULL AND deleted_at IS NULL');

        Schema::create('treasury_expense_categories', function (Blueprint $table) {
            $table->id();

            $table->string('name', 100);

            // For the categories code relies on: `carrier_fee` (what Nawris kept at settlement)
            // and `advance` (a salary advance). Null for the ones people add.
            $table->string('code', 30)->nullable();

            // «سلفة موظف» is meaningless without the employee it was handed to.
            $table->boolean('requires_employee')->default(false);

            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);

            $table->timestamps();
            $table->softDeletes()->index();
        });

        DB::statement('CREATE UNIQUE INDEX treasury_expense_categories_code_unique
            ON treasury_expense_categories (code) WHERE code IS NOT NULL AND deleted_at IS NULL');

        Schema::create('treasury_operations', function (Blueprint $table) {
            $table->id();

            // opening · deposit · withdrawal · expense · transfer · adjustment · settlement
            $table->string('type', 20);

            $table->decimal('amount', 14, 2);

            $table->foreignId('from_account_id')->nullable()->constrained('treasury_accounts');
            $table->foreignId('to_account_id')->nullable()->constrained('treasury_accounts');

            $table->foreignId('category_id')->nullable()->constrained('treasury_expense_categories');

            // Whose advance, or whom the expense was for.
            $table->foreignId('employee_id')->nullable()->constrained('users')->nullOnDelete();

            // A settlement's order. A number and not a foreign key: Treasury does not know what an
            // order is, and the column exists for filtering, not for integrity.
            $table->unsignedBigInteger('order_id')->nullable()->index();

            // «جرد الحساب»: what the system said and what was counted. The difference is the
            // movement; both figures are kept so the count can be read back later.
            $table->decimal('system_balance', 14, 2)->nullable();
            $table->decimal('counted_balance', 14, 2)->nullable();

            $table->timestamp('occurred_at');
            $table->text('notes')->nullable();

            $table->foreignId('reverses_operation_id')->nullable()->constrained('treasury_operations');

            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['type', 'occurred_at']);
        });

        DB::statement('ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_amount_positive
            CHECK (amount > 0)');

        // The shape of each type, said once where no path can get round it.
        DB::statement("ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_shape CHECK (
            (type IN ('opening', 'deposit') AND to_account_id IS NOT NULL AND from_account_id IS NULL)
            OR (type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL)
            OR (type = 'expense' AND from_account_id IS NOT NULL AND to_account_id IS NULL AND category_id IS NOT NULL)
            OR (type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL
                AND from_account_id <> to_account_id)
            OR (type = 'adjustment' AND (from_account_id IS NULL) <> (to_account_id IS NULL)
                AND system_balance IS NOT NULL AND counted_balance IS NOT NULL)
            OR (type = 'settlement' AND to_account_id IS NOT NULL AND order_id IS NOT NULL)
        )");

        // One opening per account. An opening is not reversed — a wrong count is corrected by
        // «جرد الحساب», which says so in the ledger instead of pretending the first count never was.
        DB::statement("CREATE UNIQUE INDEX treasury_operations_one_opening
            ON treasury_operations (to_account_id)
            WHERE type = 'opening' AND deleted_at IS NULL");

        DB::statement('CREATE UNIQUE INDEX treasury_operations_reverses_unique
            ON treasury_operations (reverses_operation_id)
            WHERE reverses_operation_id IS NOT NULL AND deleted_at IS NULL');

        Schema::create('treasury_movements', function (Blueprint $table) {
            $table->id();

            $table->foreignId('account_id')->constrained('treasury_accounts');

            $table->string('direction', 3);
            $table->string('kind', 30);

            // Always positive; the direction says which way.
            $table->decimal('amount', 14, 2);

            // When the money moved — not when somebody typed it.
            $table->timestamp('occurred_at');

            // Why this row exists: a morph-map alias and an id — `order_payment` 17,
            // `treasury_operation` 4 — the names the audit trail already publishes.
            $table->string('source_type', 40);
            $table->unsignedBigInteger('source_id');

            $table->foreignId('operation_id')->nullable()->constrained('treasury_operations');

            // «الطلب المرتبط» — and the key a settlement sums an order's custody by.
            $table->unsignedBigInteger('order_id')->nullable()->index();

            // The other side of a transfer or a settlement, for «من النورس» / «إلى المصرف».
            $table->foreignId('counterpart_account_id')->nullable()->constrained('treasury_accounts');

            $table->foreignId('reverses_movement_id')->nullable()->constrained('treasury_movements');

            $table->text('notes')->nullable();
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['account_id', 'occurred_at']);
            $table->index(['source_type', 'source_id']);
        });

        DB::statement('ALTER TABLE treasury_movements ADD CONSTRAINT treasury_movements_amount_positive
            CHECK (amount > 0)');

        DB::statement("ALTER TABLE treasury_movements ADD CONSTRAINT treasury_movements_direction_check
            CHECK (direction IN ('in', 'out'))");

        // **No event is posted twice.** The Nawris webhook retries, and a listener can fire again;
        // the second attempt meets this index instead of doubling a balance. Reversals are left
        // out — they have their own index below.
        DB::statement('CREATE UNIQUE INDEX treasury_movements_posted_once
            ON treasury_movements (source_type, source_id, account_id, kind, direction)
            WHERE reverses_movement_id IS NULL AND deleted_at IS NULL');

        DB::statement('CREATE UNIQUE INDEX treasury_movements_reverses_unique
            ON treasury_movements (reverses_movement_id)
            WHERE reverses_movement_id IS NOT NULL AND deleted_at IS NULL');

        $this->seed();
    }

    public function down(): void
    {
        Schema::dropIfExists('treasury_movements');
        Schema::dropIfExists('treasury_operations');
        Schema::dropIfExists('treasury_expense_categories');
        Schema::dropIfExists('treasury_accounts');
    }

    /**
     * The four accounts every fallback lands in, and the categories code refers to by code.
     *
     * Balances start at nothing; the opening count is an operation recorded on the day —
     * TREASURY-DESIGN §١١.
     */
    private function seed(): void
    {
        $now = now();

        $accounts = [
            ['name' => 'الخزنة الرئيسية', 'kind' => 'cash', 'system_code' => null, 'is_default' => true],
            ['name' => 'المصرف', 'kind' => 'bank', 'system_code' => null, 'is_default' => true],
            ['name' => 'ليبيانا', 'kind' => 'wallet', 'system_code' => null, 'is_default' => true],
            ['name' => 'النورس', 'kind' => 'custody', 'system_code' => 'nawris', 'is_default' => false],
        ];

        foreach ($accounts as $account) {
            DB::table('treasury_accounts')->insert($account + [
                'currency' => 'LYD',
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        $categories = [
            ['name' => 'رسوم شركة التوصيل', 'code' => 'carrier_fee', 'requires_employee' => false],
            ['name' => 'سلفة موظف', 'code' => 'advance', 'requires_employee' => true],
            ['name' => 'رواتب', 'code' => null, 'requires_employee' => false],
            ['name' => 'إيجار', 'code' => null, 'requires_employee' => false],
            ['name' => 'كهرباء ومياه واتصالات', 'code' => null, 'requires_employee' => false],
            ['name' => 'شحن وجمارك', 'code' => null, 'requires_employee' => false],
            ['name' => 'مسحوبات المالك', 'code' => null, 'requires_employee' => false],
            ['name' => 'مصاريف أخرى', 'code' => null, 'requires_employee' => false],
        ];

        foreach ($categories as $order => $category) {
            DB::table('treasury_expense_categories')->insert($category + [
                'is_active' => true,
                'sort_order' => $order,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }
};
