<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Support\Exceptions\DomainException;

/**
 * An edit to the lines would put the order on a different road, from a status it cannot leave
 * that road from.
 *
 * **Refused rather than left on a road its lines no longer describe.** The road is a snapshot
 * once work has started — see `ResolveOrderFlow::mayMove()` — so an order in «جاهزة للطباعة»
 * that lost its last printed line would walk on to the press with nothing to print, and one
 * that gained a وسيط line would never reach a vendor. The edit that *keeps* the road — a
 * quantity, a size swapped for another of the same kind — is never refused by this.
 */
final class EditWouldChangeTheRoad extends DomainException
{
    public static function make(OrderStatus $status, OrderFlow $from, OrderFlow $to): self
    {
        $because = $from === OrderFlow::Standard && $to === OrderFlow::NoProduction
            ? 'لن يبقى في الطلبية بند يُطبع'
            : "سينقلها من «{$from->label()}» إلى «{$to->label()}»";

        return new self(
            "لا يمكن حفظ هذه البنود والطلبية في «{$status->label()}»: {$because}."
            .' ألغِ الطلبية وأعد أخذها إن كان هذا هو المقصود'
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['items' => [$this->getMessage()]];
    }
}
