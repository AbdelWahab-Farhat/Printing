<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Events;

use Illuminate\Foundation\Events\Dispatchable;

/**
 * تحرّكت محفظة موظف. يُعلنه هذا السياق ويصغي إليه سياق الإشعارات، ولا يعرف أحدهما الآخر.
 *
 * يحمل ما يحتاجه المستمع، فلا يعود ليقرأ نموذجاً من سياقٍ غير سياقه.
 */
final class EmployeeWalletMoved
{
    use Dispatchable;

    public function __construct(
        public readonly int $entryId,
        public readonly int $employeeId,
        public readonly string $type,
        public readonly bool $isCredit,
        public readonly ?int $actorId,
    ) {}
}
