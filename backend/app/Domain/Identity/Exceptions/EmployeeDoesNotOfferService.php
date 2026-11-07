<?php

declare(strict_types=1);

namespace App\Domain\Identity\Exceptions;

use App\Domain\Identity\Enums\EmployeeServiceType;
use App\Support\Exceptions\DomainException;

/** سعرٌ لخدمةٍ لا يقدّمها هذا الموظف — اليوم: مَن ليس مصمماً. */
final class EmployeeDoesNotOfferService extends DomainException
{
    public static function make(EmployeeServiceType $service): self
    {
        return new self("هذا الموظف لا يقدّم خدمة {$service->label()}");
    }
}
