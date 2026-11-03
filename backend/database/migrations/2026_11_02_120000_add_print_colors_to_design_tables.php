<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * «ألوان الطباعة» — the exact inks a design is printed in, so the press does not guess the shade
 * off a phone screen. PRINT-COLORS.md.
 *
 * **Four columns of one shape**, each a list of `{name, code, hex}` written through
 * `AsPrintColors`, and null when there are none:
 *
 * - `customer_designs` — the artwork's own colors, and the source every copy is taken from.
 * - `order_designs` — **a copy**, taken when the design is attached to an order. It is what the
 *   press reads, and it stops moving once the order leaves the statuses that accept artwork, so
 *   an order printed last year keeps saying which inks it was printed in — the rule the file
 *   itself already follows.
 * - `design_tickets` — what the employee asks for in the brief.
 * - `design_ticket_files` — what the designer says a version was drawn in. The approved one's
 *   colors go into the customer's library with the file.
 *
 * Nullable everywhere and nothing back-filled: every design that exists today has no colors on
 * record, and that is the truth about it.
 */
return new class extends Migration
{
    /** @var list<string> */
    private array $tables = ['customer_designs', 'order_designs', 'design_tickets', 'design_ticket_files'];

    public function up(): void
    {
        foreach ($this->tables as $name) {
            Schema::table($name, function (Blueprint $table) {
                $table->json('print_colors')->nullable();
            });
        }
    }

    public function down(): void
    {
        foreach ($this->tables as $name) {
            Schema::table($name, function (Blueprint $table) {
                $table->dropColumn('print_colors');
            });
        }
    }
};
