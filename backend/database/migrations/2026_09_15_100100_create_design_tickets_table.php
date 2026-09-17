<?php

declare(strict_types=1);

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * One request for artwork, from the employee who asked to the designer who drew it.
 *
 * **Not a state of an order, and that is the first decision this table makes.** `OrderStatus`
 * already carries «قيد التصميم», and hanging the request on it was the obvious move. It is wrong
 * three ways: a customer asks for a business card before they order any bags, so a mandatory
 * order means employees opening fake ones to reach a designer; a ticket lives in the designer's
 * queue rather than on the orders screen; and «بانتظار المراجعة» and «تعديل مطلوب» added to
 * `OrderStatus` would be two new states on *every* order in the system and new branching in
 * every screen that reads one. `order_id` is therefore nullable — see
 * Docs/design-tickets/DESIGN-TICKETS-DESIGN.md §2.
 *
 * **Nor is it a second copy of `order_designs`.** That table is a conversation with the customer
 * about which version to print; this one is the assignment of work to a colleague. They meet at
 * exactly one point: an approval here writes a row into `customer_designs`, which is what
 * `order_designs` already points at — so the artwork reaches an order with no new line in the
 * `Order` context at all.
 *
 * **What this table does not hold is the files.** Both the employee's brief and the designer's
 * versions live in `design_ticket_files`; the only file reference here is
 * `approved_customer_design_id`, the row in the customer's library that the approval produced.
 * That column is the output of the whole flow, and the CHECK constraint below is what makes an
 * approved ticket that never produced one impossible rather than merely unlikely.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('design_tickets', function (Blueprint $table) {
            $table->id();

            /*
             * «تذكرة رقم كام؟» — D7, allocated from this table's own sequence the way a customer
             * gets C7 and a shortage N7.
             *
             * With a letter, like a shortage and unlike an order number: a ticket is said next to
             * the order and the customer it belongs to, and a bare number in that sentence is the
             * ambiguity the letter exists to remove.
             */
            $table->string('code', 20);

            // No cascade. A customer is deactivated in this system, never deleted.
            $table->foreignId('customer_id')->constrained('customers');

            /*
             * A snapshot, for the reason `order_items.product_name` is one — and for a second
             * reason that is the whole access-control story of this feature.
             *
             * A customer gets renamed, and a closed ticket is a record of what was asked for. But
             * more than that: **this column is what lets a designer read the customer's name
             * without holding `customers.view`.** That grant opens the customer's file, their
             * orders and their money; a designer needs six words on a card. Joining for it would
             * have forced the wider grant on the narrower job.
             */
            $table->string('customer_name');

            // The order this came off, if any. `nullOnDelete` is declared for the shape rather
            // than the sweep — orders are soft-deleted — but a ticket outliving its order is the
            // correct answer either way: the artwork was still drawn.
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();

            // What is read in the queue, and the label the approved design inherits.
            $table->string('title');

            $table->text('description');

            /*
             * Split from `description` rather than appended to it, because the two are read at
             * different moments: the description is on the card in the list, and the instructions
             * are only opened once somebody has decided to take the job. One field would put a
             * paragraph of typography notes on every row of the queue.
             */
            $table->text('instructions')->nullable();

            $table->string('status', 20)->default(DesignTicketStatus::New->value);

            // Whoever asked. They are the one who reviews, and the one the status notifications
            // go back to. `nullOnDelete` on every user reference here: an employee leaves, and
            // the ticket is still a ticket.
            $table->foreignId('requested_by_user_id')->nullable()
                ->constrained('users')->nullOnDelete();

            /*
             * **The designer this was addressed to, which is not the same fact as who took it.**
             *
             * Null is «الطابور المشترك» — a real and common state rather than missing data, the
             * same way `shortages.assigned_to_user_id` is. An employee who does not know which
             * designer is free leaves it empty and the first one to accept claims it.
             */
            $table->foreignId('assigned_designer_id')->nullable()
                ->constrained('users')->nullOnDelete();

            /*
             * **Who actually took it** — the column the brief's «لا تضيع هوية المصمم الذي استلم
             * الطلب» is about.
             *
             * Deliberately separate from `assigned_designer_id`: the first is an intention that a
             * supervisor may change, the second is a fact that happened at a moment. Folding them
             * into one column would mean a reassignment could quietly rewrite who did the work.
             */
            $table->foreignId('accepted_by_user_id')->nullable()
                ->constrained('users')->nullOnDelete();
            $table->timestamp('accepted_at')->nullable();

            // Who signed the artwork off, and when the ticket closed. Separate from
            // `requested_by_user_id` because a colleague may review in somebody's absence, and
            // «من وافق؟» is the question an argument about a printed bag actually asks.
            $table->foreignId('approved_by_user_id')->nullable()
                ->constrained('users')->nullOnDelete();
            $table->timestamp('completed_at')->nullable();

            /*
             * **The output of the whole flow**: the row in the customer's library that the
             * approval created.
             *
             * No cascade, and none is needed — `customer_designs` never really deletes a file.
             * This is also the back-reference's other end: the design knows its ticket through
             * `customer_designs.design_ticket_id`, and the ticket knows its design here, because
             * both directions are asked on screens that have only one of the two in hand.
             */
            $table->foreignId('approved_customer_design_id')->nullable()
                ->constrained('customer_designs');

            // Why a ticket was called off. Required by the action when cancelling, for the same
            // reason a rejection's is: a cancellation with no reason turns the history into a
            // count. Not a CHECK, because the database cannot express "required for one value"
            // without knowing about every future status.
            $table->text('cancellation_reason')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            // The list's own order: newest first, filtered by status.
            $table->index(['status', 'id']);

            // «ما المُسنَد إليّ ولم يُغلق؟» — the designer's queue.
            $table->index(['assigned_designer_id', 'status']);

            // «ما الذي ينتظر مراجعتي؟» — the requester's side of the same question.
            $table->index(['requested_by_user_id', 'status']);

            // "Everything this customer has asked us to draw", the link from the customer screen.
            $table->index('customer_id');
            $table->index('order_id');
        });

        // Partial, like every unique index in this schema: a removed ticket releases its code.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX design_tickets_code_unique
                ON design_tickets (code)
                WHERE deleted_at IS NULL
        SQL);

        /*
         * An accepted ticket has a taker and a time; an unaccepted one has neither.
         *
         * Two columns that can only be right or wrong together, so the database says so. The
         * alternative — trusting every present and future writer to set both — is exactly the
         * kind of invariant RULES §8 says belongs here rather than only in an action.
         */
        DB::statement(<<<'SQL'
            ALTER TABLE design_tickets
                ADD CONSTRAINT design_tickets_acceptance_shape CHECK (
                    (accepted_at IS NULL) = (accepted_by_user_id IS NULL)
                )
        SQL);

        /*
         * **«مكتمل» means all three of these, or it is not «مكتمل».**
         *
         * Closed, approved by a named person, and it produced a row in the customer's library.
         * This is the constraint that makes the brief's headline promise — "التصميم النهائي فقط
         * هو الذي يضاف إلى حساب الزبون كتصميم معتمد" — unrepresentable when wrong rather than a
         * step inside an action that a later author can forget to call.
         */
        $completed = DesignTicketStatus::Completed->value;

        DB::statement(<<<SQL
            ALTER TABLE design_tickets
                ADD CONSTRAINT design_tickets_completion_shape CHECK (
                    status <> '{$completed}'
                    OR (
                        completed_at IS NOT NULL
                        AND approved_by_user_id IS NOT NULL
                        AND approved_customer_design_id IS NOT NULL
                    )
                )
        SQL);

        /*
         * A cancelled ticket says why, and nothing else carries a reason.
         *
         * The second half matters as much as the first: a reason left behind on a ticket that was
         * later reopened would read as an explanation of its current state, which it is not.
         */
        $cancelled = DesignTicketStatus::Cancelled->value;

        DB::statement(<<<SQL
            ALTER TABLE design_tickets
                ADD CONSTRAINT design_tickets_cancellation_shape CHECK (
                    (status = '{$cancelled}' AND cancellation_reason IS NOT NULL)
                    OR
                    (status <> '{$cancelled}' AND cancellation_reason IS NULL)
                )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('design_tickets');
    }
};
