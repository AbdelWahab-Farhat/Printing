<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * تحويلُ التذكرة إلى من لا يصلح صاحباً لها: صاحبُها نفسه، أو الزميلُ الذي وُجّهت إليه — فتصير
 * تذكرةً بين الشخص ونفسه، وهو ما يرفضه الجدول أيضاً (`internal_tickets_two_parties`).
 */
final class InvalidNewOwner extends DomainException
{
    public static function isAlreadyOwner(): self
    {
        return new self('هذا الموظف صاحب التذكرة أصلاً');
    }

    public static function isTheAssignee(): self
    {
        return new self('لا تُحوَّل التذكرة إلى الزميل الذي وُجّهت إليه');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['new_owner_id' => [$this->getMessage()]];
    }
}
