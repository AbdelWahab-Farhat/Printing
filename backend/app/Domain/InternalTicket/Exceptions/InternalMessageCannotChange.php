<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Exceptions;

use App\Domain\InternalTicket\Models\InternalTicketMessage;
use App\Support\Exceptions\DomainException;

/**
 * تعديلُ رسالةٍ أو سحبُها بما لا يملكه هذا الموظف: ليست له، أو مضت المهلة، أو أُغلقت التذكرة.
 *
 * الجملةُ هي {@see InternalTicketMessage::mutationBlockReason()} نفسها، التي يرسلها المورد مع كل
 * رسالة — فلا يُقال للموظف في الرفض غيرُ ما قيل له وهو يرى الزرّ مطفأً.
 */
final class InternalMessageCannotChange extends DomainException
{
    public static function because(string $reason): self
    {
        return new self($reason);
    }

    public function httpStatus(): int
    {
        return 403;
    }
}
