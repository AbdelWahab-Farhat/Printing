<?php

declare(strict_types=1);

namespace App\Domain\Audit;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Support\Arr;

/**
 * أعمدةٌ سجلُّها لقارئٍ دون قارئ: ما يتقاضاه موظف.
 *
 * **ليس {@see AuditHiddenAttributes}**: تلك ضجيجٌ لا يهمّ أحداً، وتُخفى عن الجميع. وهذه يهمّ تاريخها مَن
 * يملكها، ويراه هو وحده. والرد نفسه يغيب عنه المفتاح، فلا يقرؤه من السجل.
 */
final class AuditRestrictedAttributes
{
    /**
     * @var array<string, array<string, list<PermissionName>>>
     */
    private const READERS = [
        'design_ticket' => [
            'designer_pay' => [PermissionName::ManageDesignTickets, PermissionName::ReviewDesignTickets],
        ],
        'employee_service' => [
            'suggested_price' => [PermissionName::ManageUserSalaries],
        ],
    ];

    /** ما يبقى من القيم لهذا القارئ. */
    public static function strip(mixed $values, ?AuditSubject $subject, ?User $reader): mixed
    {
        if (! is_array($values) || $subject === null) {
            return $values;
        }

        foreach (self::READERS[$subject->value] ?? [] as $column => $permissions) {
            $mayRead = $reader?->canAny(array_map(fn (PermissionName $p) => $p->value, $permissions)) === true;

            if (! $mayRead) {
                $values = Arr::except($values, [$column]);
            }
        }

        return $values;
    }
}
