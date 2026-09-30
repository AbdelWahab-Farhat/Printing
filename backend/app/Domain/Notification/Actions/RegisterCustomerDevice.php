<?php

declare(strict_types=1);

namespace App\Domain\Notification\Actions;

use App\Domain\Notification\Enums\DevicePlatform;
use App\Domain\Notification\Models\CustomerDeviceToken;
use Illuminate\Support\Carbon;

/**
 * يتذكّر هاتفَ عميل، ليُوقَظ حين تتحرّك طلبيته أو يُردّ عليه في الدعم.
 *
 * **استبدالٌ على الرمز لا إضافة — وهي خاصيّةُ أمانٍ** كما في {@see RegisterDeviceToken}: هاتفٌ واحد
 * خرج منه عميلٌ ودخل غيره يسجّل الرمزَ نفسه، فينتقل الصفُّ إلى الثاني. صفٌّ ثانٍ كان سيُبقي الأوّل
 * يتلقّى «طلبيتك في الطريق إليك» عن طلبياتٍ ليست له.
 */
final readonly class RegisterCustomerDevice
{
    public function handle(int $customerId, string $token, DevicePlatform $platform): CustomerDeviceToken
    {
        $device = CustomerDeviceToken::query()->where('token', $token)->first() ?? new CustomerDeviceToken;

        $device->customer_id = $customerId;
        $device->token = $token;
        $device->platform = $platform;
        $device->last_used_at = Carbon::now();
        $device->save();

        return $device;
    }
}
