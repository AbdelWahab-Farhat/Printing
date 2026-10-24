<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Support\Exceptions\DomainException;

/**
 * تعديلُ رسالةٍ أو سحبُها بما لا يملكه هذا الموظف: ليست له، أو مضت المهلة، أو سُحبت.
 *
 * الجملةُ هي {@see DesignTicketMessage::mutationBlockReason()} نفسها، التي يرسلها المورد مع كل
 * رسالة — فلا يُقال للموظف في الرفض غيرُ ما قيل له وهو يرى الزرّ مطفأً. **والتذكرةُ المغلقة ليست
 * هنا**: تلك {@see DesignConversationIsClosed}، ٤٢٢ لا ٤٠٣.
 */
final class DesignTicketMessageCannotChange extends DomainException
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
