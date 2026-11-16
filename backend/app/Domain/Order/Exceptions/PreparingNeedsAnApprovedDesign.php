<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Support\TransitionFields;
use App\Support\Exceptions\DomainException;

/**
 * Sending an order with artwork to the warehouse before any version of it is approved.
 *
 * **«لا يختار الموظف تجهيز للطباعة إذا كان الطلب يحتاج تصميماً ولم يُعتمد بعد»** (owner's status
 * document, 2026-11-15). The warehouse gathers goods for one file; gathering them for a design
 * that may still change is the waste the reordered road exists to avoid.
 *
 * An order "has artwork" when it carries any version, or when its design source is not «بدون
 * تصميم». The way through is the «اعتماد آخر نسخة» tick on the same move, or «قيد التصميم».
 */
final class PreparingNeedsAnApprovedDesign extends DomainException
{
    public static function make(bool $hasAVersion): self
    {
        return new self($hasAVersion
            ? 'التصميم غير معتمد — اعتمد آخر نسخة قبل التجهيز، أو أرسل الطلبية إلى «قيد التصميم»'
            : 'الطلبية بلا تصميم معتمد — أرسلها إلى «قيد التصميم» أولاً');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['fields.'.TransitionFields::APPROVE_DESIGN => [$this->getMessage()]];
    }
}
