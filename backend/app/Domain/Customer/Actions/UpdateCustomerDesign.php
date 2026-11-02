<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\Order\Actions\AddOrderDesign;
use App\Domain\Order\Actions\RefreshOrderDesignColors;
use Illuminate\Support\Facades\DB;

/**
 * Renames a design, rewrites its notes, or corrects its print colors — never its file.
 *
 * **The colors are the reason this is an action rather than an `update()` in the controller.**
 * Every order holds its own copy of them ({@see AddOrderDesign}), and a correction made here has
 * to reach the orders still waiting to be printed, or the press reads the old inks off the order
 * while the library says the new ones. One transaction, so the design and its copies never
 * disagree.
 */
final class UpdateCustomerDesign
{
    public function __construct(private readonly RefreshOrderDesignColors $refreshOrders) {}

    /**
     * @param  array<string, mixed>  $attributes  already validated: label, notes, print_colors
     */
    public function __invoke(CustomerDesign $design, array $attributes): CustomerDesign
    {
        $attributes = array_intersect_key($attributes, array_flip(['label', 'notes', 'print_colors']));

        return DB::transaction(function () use ($design, $attributes): CustomerDesign {
            $before = $design->print_colors;

            $design->update($attributes);

            if (array_key_exists('print_colors', $attributes)) {
                ($this->refreshOrders)($design, $before);
            }

            return $design->refresh();
        });
    }
}
