<?php

declare(strict_types=1);

namespace App\Domain\Customer\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A customer tried to change print colors an employee has already put codes on.
 *
 * The codes are staff's work, matched against a swatch book; letting the customer edit the list
 * afterwards would undo it silently. The way to a change is a conversation — «تواصل معنا».
 */
final class PrintColorsAreConfirmed extends DomainException
{
    public static function make(): self
    {
        return new self('ألوان هذا التصميم اعتمدها فريقنا — لتغييرها تواصل معنا');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['print_colors' => [$this->getMessage()]];
    }
}
