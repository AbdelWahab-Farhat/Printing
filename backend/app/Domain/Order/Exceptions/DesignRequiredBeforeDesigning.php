<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * «قيد التصميم» is a state with something in it: at least one version of the artwork.
 *
 * The move offers a field for it, so a person using the app meets the friendlier message from
 * validation and never this. This is the same rule for every other caller — and for the day the
 * app forgets to send the field.
 *
 * `design_source = none` is exempt, for the reason it is always exempt: a reprint has no design
 * conversation to have.
 */
final class DesignRequiredBeforeDesigning extends DomainException
{
    public static function make(): self
    {
        return new self('لا يمكن تحويل الطلبية إلى «قيد التصميم» بدون تصميم واحد على الأقل');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['fields.design_ids' => [$this->getMessage()]];
    }
}
