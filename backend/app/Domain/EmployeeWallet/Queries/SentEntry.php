<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Queries;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Exceptions\EmployeeWalletTokenReused;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;

/**
 * الحركة التي كتبها هذا الطلب من قبل، برمز التطبيق — أو null حين يكون الرمز جديداً.
 *
 * **يُسأل تحت قفل الموظف**: نسختان من الطلب نفسه تتقابلان هنا، والفهرسُ الفريد تحتها حارسٌ أخير لا
 * الطريق المعتاد. ورمزٌ كتب نوعاً آخر ليس إعادةً، فيُرفض بدل أن يُجاب بسطرٍ لم يُسأل عنه.
 */
final class SentEntry
{
    public function __invoke(int $userId, ?string $clientToken, EmployeeWalletEntryType $type): ?EmployeeWalletEntry
    {
        if ($clientToken === null) {
            return null;
        }

        $entry = EmployeeWalletEntry::query()
            ->where('user_id', $userId)
            ->where('client_token', $clientToken)
            ->first();

        if ($entry !== null && $entry->type !== $type) {
            throw EmployeeWalletTokenReused::make();
        }

        return $entry;
    }
}
