<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Support;

use App\Domain\Identity\Models\User;

/**
 * لا أحد يودع في محفظته أو يسحب منها أو يعدّلها أو يعكس فيها، والمدير مستثنى — قرار صاحب العمل
 * ٢٠٢٦-١١-٠٥. الصلاحيةُ سؤالٌ آخر، يُسأل عند الباب.
 *
 * **مرّةً واحدة هنا** لأن الخدمة ترفض بها، والمورد يقرأها لكل سطر، والتطبيق يبني أزراره عليها.
 */
final class OwnWalletRule
{
    public static function allows(User $actor, int $walletUserId): bool
    {
        return (int) $actor->getKey() !== $walletUserId || $actor->isAdmin();
    }
}
