<?php

declare(strict_types=1);

namespace App\Domain\Notification\Models;

use App\Domain\Customer\Models\Customer;
use App\Domain\Notification\Enums\DevicePlatform;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * جهازُ عميلٍ طلب أن يُوقَظ — نظيرُ {@see DeviceToken} في تطبيق العميل.
 *
 * **يُحذف حذفاً حقيقياً** كنظيره، والترحيل يقول لماذا: رمزُ FCM عنوانٌ لا سجلّ. و`ModelConventionsTest`
 * يستثنيه بجانبه.
 *
 * **الرمزُ لعميلٍ واحدٍ في كل لحظة**، والفهرسُ الفريد على `token` هو ما يفرض ذلك — انظر
 * RegisterCustomerDevice.
 *
 * @property int $id
 * @property int $customer_id
 * @property string $token
 * @property DevicePlatform $platform
 * @property Carbon|null $last_used_at
 */
class CustomerDeviceToken extends Model
{
    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'platform' => DevicePlatform::class,
            'last_used_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
