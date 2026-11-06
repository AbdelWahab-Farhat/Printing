<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * «مستحق موظف» نوعُ عمليةٍ مستقلّ — EMPLOYEE-WALLET-DESIGN §٤.
 *
 * شكلُ المصروف نفسه — حسابٌ يخرج منه وتصنيف — لكنّ `expense` يُعكس باليد من تبويب «المصاريف»، وعكسٌ
 * من هناك يُسقط المصروف ويترك سطر المحفظة قائماً، فينفصل الحساب عن المحافظ. النوعُ الجديد يقول ذلك
 * في مكانٍ واحد: `OperationType::isReversibleByHand()`.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE treasury_operations DROP CONSTRAINT treasury_operations_shape');
        DB::statement("ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_shape CHECK (
            (type = 'opening' AND (from_account_id IS NULL) <> (to_account_id IS NULL))
            OR (type = 'deposit' AND to_account_id IS NOT NULL AND from_account_id IS NULL)
            OR (type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL)
            OR (type IN ('expense', 'wallet_expense') AND from_account_id IS NOT NULL AND to_account_id IS NULL
                AND category_id IS NOT NULL)
            OR (type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL
                AND from_account_id <> to_account_id)
            OR (type = 'adjustment' AND (from_account_id IS NULL) <> (to_account_id IS NULL)
                AND system_balance IS NOT NULL AND counted_balance IS NOT NULL)
            OR (type = 'settlement' AND to_account_id IS NOT NULL AND order_id IS NOT NULL)
        )");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE treasury_operations DROP CONSTRAINT treasury_operations_shape');
        DB::statement("ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_shape CHECK (
            (type = 'opening' AND (from_account_id IS NULL) <> (to_account_id IS NULL))
            OR (type = 'deposit' AND to_account_id IS NOT NULL AND from_account_id IS NULL)
            OR (type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL)
            OR (type = 'expense' AND from_account_id IS NOT NULL AND to_account_id IS NULL AND category_id IS NOT NULL)
            OR (type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL
                AND from_account_id <> to_account_id)
            OR (type = 'adjustment' AND (from_account_id IS NULL) <> (to_account_id IS NULL)
                AND system_balance IS NOT NULL AND counted_balance IS NOT NULL)
            OR (type = 'settlement' AND to_account_id IS NOT NULL AND order_id IS NOT NULL)
        )");
    }
};
