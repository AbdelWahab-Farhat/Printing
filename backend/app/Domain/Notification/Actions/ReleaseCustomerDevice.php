<?php

declare(strict_types=1);

namespace App\Domain\Notification\Actions;

use App\Domain\Notification\Models\CustomerDeviceToken;

/**
 * ينسى هاتفَ عميل — عند الخروج، وحين يُطفئ الإشعارات.
 *
 * **مقيَّدٌ بصاحبه**، كنظيره {@see ReleaseDeviceToken}: لا يُنسى جهازُ أحدٍ بتخمين رمزه.
 */
final readonly class ReleaseCustomerDevice
{
    /**
     * @return bool هل نُسي جهازٌ فعلاً — و`false` عاديٌّ لا فشل: خروجٌ مرتين، أو نسخةٌ لم تسجّل قط
     */
    public function handle(int $customerId, string $token): bool
    {
        return CustomerDeviceToken::query()
            ->where('customer_id', $customerId)
            ->where('token', $token)
            ->delete() > 0;
    }
}
