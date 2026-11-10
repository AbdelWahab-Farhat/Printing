<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\Money;
use Illuminate\Console\Command;
use Illuminate\Console\ConfirmableTrait;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Drops the fractions from the lines of orders that are still running.
 *
 * Lines are billed in whole dinars since 2026-11-05 — {@see Money::wholeDinars()}. An order taken
 * before that keeps its fraction until something re-prices the line, and this is the one-off that
 * brings the open ones into line. **It runs only when somebody runs it**; no deploy triggers it.
 *
 * **Closed orders are not touched.** Delivered, settled, cancelled and rejected orders record what
 * was billed and what came back, and were paid to the fraction.
 *
 * **Three kinds of order it names and leaves as they stand**, because moving them makes something
 * else wrong:
 *
 *   - out with the courier: the parcel carries the old COD, and the customer is about to pay it.
 *   - already paid past the new total: dropping the fraction would create a refund of pennies.
 *   - a discount that no longer fits the smaller total: `RecalculateOrderTotals` would refuse it.
 *
 * Rows that need nothing are not written to. Re-running it changes nothing.
 */
class DropFractionsFromOrderTotals extends Command
{
    use ConfirmableTrait;

    protected $signature = 'orders:drop-fractions
                            {--dry-run : Report what would change and write nothing}
                            {--force : Skip the confirmation prompt outside local}';

    protected $description = 'Bill the lines of open orders in whole dinars, leaving closed orders alone';

    public function handle(RecalculateOrderTotals $recalculate): int
    {
        $dryRun = (bool) $this->option('dry-run');

        if (! $dryRun && ! $this->confirmToProceed()) {
            return self::FAILURE;
        }

        $corrected = 0;
        $moved = '0.00';

        /** @var list<string> $left */
        $left = [];

        Order::query()
            ->with('items')
            ->orderBy('id')
            ->each(function (Order $order) use ($recalculate, $dryRun, &$corrected, &$moved, &$left): void {
                if ($order->status->isClosed()) {
                    return;
                }

                $lines = $this->fractionalLines($order);

                if ($lines->isEmpty()) {
                    return;
                }

                $note = $this->whyItStays($order, $lines);

                if ($note !== null) {
                    $left[] = "#{$order->code} — {$note}";

                    return;
                }

                $before = (string) $order->grand_total;
                $after = $this->totalAfter($order, $lines);

                if (! $dryRun) {
                    DB::transaction(function () use ($order, $lines, $recalculate): void {
                        $lines->each(fn (OrderItem $line) => $line
                            ->forceFill(['line_total' => $line->deriveLineTotal()])
                            ->save());

                        ($recalculate)($order->load('items'));
                    });
                }

                $corrected++;
                $moved = bcadd($moved, bcsub($before, $after, Money::SCALE), Money::SCALE);
            });

        $this->info($dryRun
            ? "تجربة: {$corrected} طلبية ستُرفع كسورها، بمجموع {$moved}"
            : "تم: {$corrected} طلبية رُفعت كسورها، بمجموع {$moved}");

        if ($left !== []) {
            $this->newLine();
            $this->warn('طلبيات لم تُمس:');

            foreach ($left as $line) {
                $this->line("  {$line}");
            }
        }

        return self::SUCCESS;
    }

    /**
     * Priced lines still holding a fraction. Only those: a whole line is left exactly as it stands
     * even where re-deriving it would give another figure, because that is not this repair.
     *
     * @return Collection<int, OrderItem>
     */
    private function fractionalLines(Order $order): Collection
    {
        return $order->items
            ->filter(fn (OrderItem $line) => $line->isPriced() && ! Money::isWhole((string) $line->line_total))
            ->values()
            ->toBase();
    }

    /**
     * The order's total once [$lines] are whole, asked without writing, so a `--dry-run` fires no
     * model events on a live database.
     *
     * @param  Collection<int, OrderItem>  $lines
     */
    private function totalAfter(Order $order, Collection $lines): string
    {
        return Money::round(bcsub($this->baseAfter($order, $lines), (string) $order->discount, 8));
    }

    /**
     * @param  Collection<int, OrderItem>  $lines
     */
    private function baseAfter(Order $order, Collection $lines): string
    {
        $dropped = $lines->reduce(
            fn (string $sum, OrderItem $line) => bcadd(
                $sum,
                bcsub((string) $line->line_total, (string) $line->deriveLineTotal(), 8),
                8,
            ),
            '0',
        );

        $designFee = $order->design_source->isChargeable() ? (string) $order->design_fee : '0.00';

        return Money::round(bcsub(
            Money::sum((string) $order->items_total, $designFee, (string) $order->additional_cost),
            $dropped,
            8,
        ));
    }

    /**
     * Why this order is left alone, or null when it can move.
     *
     * @param  Collection<int, OrderItem>  $lines
     */
    private function whyItStays(Order $order, Collection $lines): ?string
    {
        if (! $order->destinationIsEditable()) {
            return 'مع المندوب، والطرد يحمل المبلغ القديم';
        }

        if (bccomp((string) $order->discount, $this->baseAfter($order, $lines), Money::SCALE) > 0) {
            return "الخصم {$order->discount} أكبر من الإجمالي بعد رفع الكسور";
        }

        $covered = bcsub((string) $order->grand_total, $order->remainingAmount(), Money::SCALE);

        if (bccomp($covered, $this->totalAfter($order, $lines), Money::SCALE) > 0) {
            return "المدفوع {$covered} يتجاوز الإجمالي بعد رفع الكسور";
        }

        return null;
    }
}
