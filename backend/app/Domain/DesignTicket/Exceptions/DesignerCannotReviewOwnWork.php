<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Domain\Identity\Enums\PermissionName;
use App\Support\Exceptions\DomainException;

/**
 * The person who uploaded a version tried to pass a verdict on it.
 *
 * **The rule the brief's closing note asks for, and it has to live here rather than on the roles
 * screen.** Withholding `design_tickets.review` from the designer role is necessary and not
 * sufficient: an administrator holds every permission through `Gate::before`, so a permission
 * alone could never stop one person drawing a bag and signing it off. Separating execution from
 * approval is only real if the domain refuses it.
 *
 * The precedent is exact: {@see PermissionName::ConfirmDepositReceipt} refuses the tick to
 * whoever claimed the payment, so at least two people must be involved before money is called
 * received. Same shape, same reason — a claim and its verification are not one person's job.
 */
final class DesignerCannotReviewOwnWork extends DomainException
{
    public static function make(): self
    {
        return new self('لا يمكن مراجعة تصميم رفعته بنفسك — الاعتماد من مسؤول آخر');
    }
}
