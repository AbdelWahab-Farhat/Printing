<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\Exceptions\PrintColorsAreConfirmed;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\Customer\Support\PrintColors;
use App\Domain\Order\Actions\RefreshOrderDesignColors;
use Illuminate\Support\Facades\DB;

/**
 * The customer chooses the inks on their own design — names and swatches, never codes.
 *
 * PRINT-COLORS.md §8. Three rules, all here rather than in the request:
 *
 * - **No codes.** Whatever arrives is passed through {@see PrintColors::withoutCodes()}; the code
 *   is what the press matches and an employee writes it.
 * - **Only until an employee has written one** ({@see CustomerDesign::printColorsAreConfirmed()}).
 *   After that the list is a confirmed answer, and a change goes through «تواصل معنا».
 * - **It reaches the orders still waiting to print**, exactly as a staff edit does — through
 *   {@see RefreshOrderDesignColors}, in the same transaction.
 */
final class ChooseDesignColors
{
    public function __construct(private readonly RefreshOrderDesignColors $refreshOrders) {}

    /**
     * @param  array<int, mixed>|null  $colors  already validated
     *
     * @throws PrintColorsAreConfirmed
     */
    public function __invoke(CustomerDesign $design, ?array $colors): CustomerDesign
    {
        if ($design->printColorsAreConfirmed()) {
            throw PrintColorsAreConfirmed::make();
        }

        return DB::transaction(function () use ($design, $colors): CustomerDesign {
            $before = $design->print_colors;

            $design->print_colors = PrintColors::withoutCodes($colors);
            $design->save();

            ($this->refreshOrders)($design, $before);

            return $design->refresh();
        });
    }
}
