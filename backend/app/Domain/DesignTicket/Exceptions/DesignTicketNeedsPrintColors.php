<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A ticket for an order our press prints, with its colours missing or incomplete — on the brief
 * when it is raised, or on a version when it is submitted. Approval puts that version and its
 * colours on the order, and a print order needs them (PRINT-COLORS.md §9–§10).
 */
final class DesignTicketNeedsPrintColors extends DomainException
{
    public static function make(): self
    {
        return new self('حدّد ألوان الطباعة — كم لوناً، وما هو كل لون بعيّنته. تذكرة طلبية الطباعة لا تُرسل دونها');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['print_colors' => [$this->getMessage()]];
    }
}
