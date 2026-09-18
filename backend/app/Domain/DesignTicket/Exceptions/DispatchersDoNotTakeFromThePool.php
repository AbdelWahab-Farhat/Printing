<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Domain\DesignTicket\Actions\AcceptDesignTicket;
use App\Support\Exceptions\DomainException;

/**
 * Somebody whose part is handing the work out tried to take it themselves.
 *
 * **«قبول الطلب» means «أنا آخذها وسأرسمها بنفسي»**, and it is the step that locks every other
 * designer out and makes the acceptor the only account allowed to upload. A role that can hand a
 * ticket to a designer is dispatching, not drawing, and its action is «إسناد إلى مصمم».
 *
 * Distinct from {@see DesignTicketBelongsToAnotherDesigner}, which answers somebody reaching for
 * a colleague's ticket. This answers somebody reaching into the unclaimed pool for work that is
 * not their job — so the message names the button they wanted instead.
 *
 * The rule holds for the pool alone; a ticket addressed to them by name is theirs to take. See
 * {@see AcceptDesignTicket}.
 */
final class DispatchersDoNotTakeFromThePool extends DomainException
{
    public static function make(): self
    {
        return new self('من يوزّع العمل لا يسحب من الطابور المشترك — استعمل «إسناد إلى مصمم»');
    }
}
