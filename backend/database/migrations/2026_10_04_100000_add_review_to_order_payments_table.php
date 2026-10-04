<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «مراجعة الدفعات» — somebody holding the grant saying they checked an entry and it is right.
 *
 * **Three columns, and the first is what keeps the queue honest.** `requires_review` is stamped by
 * the two actions that write money moving — `RecordOrderPayment` and `RefundOrderPayment` — and by
 * nothing else. A reversal, a write-off and a carrier settlement moved no cash of ours and have
 * nothing to check. And **every row already in the table stays `false`**: the owner exempted the
 * payments taken before this existed, so the queue opens empty rather than holding the whole
 * history of the shop.
 *
 * `reviewed_at` and `reviewed_by` are the review itself, written and cleared together by
 * `ReviewOrderPayment` — the one exception to «a ledger row is never updated», and a narrow one:
 * the money columns stay untouchable, and both movements land in the audit log.
 *
 * **Nothing reads the review to decide anything.** No status change, no settlement and no
 * treasury figure waits for it — the same line `is_deposit_received` holds, and for the same
 * reason. What it feeds is the reviewer's queue, which the partial index below is built for.
 *
 * See Docs/payments/PAYMENT-REVIEW-AND-OVERPAY.md.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_payments', function (Blueprint $table) {
            $table->boolean('requires_review')->default(false)->after('treasury_account_id');
            $table->timestamp('reviewed_at')->nullable()->after('requires_review');

            // `nullOnDelete`, like `deposit_confirmed_by`: an employee leaving must not take the
            // record of the check with them — only the name behind it goes.
            $table->foreignId('reviewed_by')
                ->nullable()
                ->after('reviewed_at')
                ->constrained('users')
                ->nullOnDelete();
        });

        // A row nobody was asked to check cannot have been checked: the queue and the badge both
        // read `requires_review` first, and a stamp on an exempt row would be a review of nothing.
        DB::statement(
            'ALTER TABLE order_payments ADD CONSTRAINT order_payments_review_needs_a_reviewable_entry '
            .'CHECK (reviewed_at IS NULL OR requires_review = true)'
        );

        DB::statement(
            'CREATE INDEX order_payments_awaiting_review_index ON order_payments (paid_at) '
            .'WHERE requires_review = true AND reviewed_at IS NULL AND deleted_at IS NULL'
        );
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS order_payments_awaiting_review_index');
        DB::statement('ALTER TABLE order_payments DROP CONSTRAINT IF EXISTS order_payments_review_needs_a_reviewable_entry');

        Schema::table('order_payments', function (Blueprint $table) {
            $table->dropConstrainedForeignId('reviewed_by');
            $table->dropColumn(['requires_review', 'reviewed_at']);
        });
    }
};
