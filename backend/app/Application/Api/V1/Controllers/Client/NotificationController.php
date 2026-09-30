<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers\Client;

use App\Application\Api\V1\Requests\Notification\RegisterDeviceRequest;
use App\Application\Api\V1\Requests\Notification\ReleaseDeviceRequest;
use App\Application\Controller;
use App\Domain\Customer\Models\Customer;
use App\Domain\Notification\NotificationService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Push notifications
 *
 * هاتفُ العميل يطلب أن يُوقَظ حين تتحرّك طلبيته أو يُردّ عليه في الدعم، ويطلب أن يُنسى.
 *
 * **دفعٌ فقط — لا صندوقَ بريدٍ ولا جرس.** العميلُ يرى مرحلةَ طلبيته وشارةَ الدعم في التطبيق نفسه،
 * فالدفعُ نداءٌ إليه ليفتحه، والبيانات المرفقة (`data.route`) تقول إلى أين: `/orders/{id}` أو
 * `/support/{id}`. ولا `notification_id` فيها، خلافاً لتطبيق الموظفين.
 *
 * **لا رقمَ عميلٍ في المسار**، كسائر هذا الملف: الجهازُ يُسجَّل لصاحب التوكن، ولا يُنسى إلا جهازُه.
 */
class NotificationController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly NotificationService $notifications) {}

    /**
     * Register this device for push
     *
     * يُستدعى بعد الدخول، وحين تُشغَّل الإشعارات، وكلما بدّل FCM الرمز. تسجيلُ رمزٍ معروف يُحدّث
     * صفَّه ولا يضيف ثانياً — ورمزٌ سجّله عميلٌ آخر ينتقل إلى هذا الحساب، فلا يبقى الهاتفُ يوقظ
     * صاحبه السابق بطلبياتٍ ليست له.
     */
    public function registerDevice(RegisterDeviceRequest $request): JsonResponse
    {
        $this->notifications->registerCustomerDevice(
            (int) $this->customer($request)->getKey(),
            $request->token(),
            $request->platform(),
        );

        return $this->successMessage('تم تسجيل الجهاز');
    }

    /**
     * Release this device
     *
     * **يُستدعى عند الخروج**، قبل أن يُمسح الرمز من الهاتف. نسيانُ جهازٍ لم يُسجَّل قط نجاحٌ لا خطأ،
     * وجهازُ عميلٍ آخر لا يُمسّ.
     */
    public function releaseDevice(ReleaseDeviceRequest $request): JsonResponse
    {
        $this->notifications->releaseCustomerDevice((int) $this->customer($request)->getKey(), $request->token());

        return $this->successMessage('تم إلغاء تسجيل الجهاز');
    }

    /**
     * العميلُ صاحب التوكن، مُضيَّقاً من عقد الحارس إلى النموذج. `auth:customer` على مجموعة المسارات
     * هو ما يجعل التأكيد صحيحاً.
     */
    private function customer(Request $request): Customer
    {
        $customer = $request->user();

        assert($customer instanceof Customer);

        return $customer;
    }
}
