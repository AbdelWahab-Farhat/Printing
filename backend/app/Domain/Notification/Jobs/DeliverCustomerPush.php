<?php

declare(strict_types=1);

namespace App\Domain\Notification\Jobs;

use App\Domain\Notification\Enums\FcmSendResult;
use App\Domain\Notification\Models\CustomerDeviceToken;
use App\Domain\Notification\Support\FcmClient;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Carbon;

/**
 * دفعةٌ واحدة، إلى جهاز عميلٍ واحد — نظيرُ {@see DeliverPushNotification}.
 *
 * **يحمل الجهازَ رقماً والكلماتِ نصّاً**، وهنا يفترق عن نظيره: ذاك يحمل رقمَ إشعارٍ ويرسم كلماته
 * من صفّه ساعةَ يعمل، وهذا لا صفَّ له يُرسم منه. فالكلماتُ لقطةٌ من ساعة الحدث — وهذا صحيحٌ لدفعةٍ
 * تُقرأ مرةً على شاشةٍ مقفلة، والتطبيقُ يجلب الحالَ الراهنة بعد اللمس.
 *
 * والجهازُ رقمٌ لا نموذج، ليُقرأ كما هو ساعةَ العمل: جهازٌ نُسي عند الخروج بين الإدراج والتنفيذ
 * لا يُدفع إليه.
 */
class DeliverCustomerPush implements ShouldQueue
{
    use Queueable;

    /** ثلاثُ محاولاتٍ بفجواتٍ متزايدة، كنظيره وللسبب نفسه. */
    public int $tries = 3;

    /** @var list<int> */
    public array $backoff = [30, 300];

    public function __construct(
        public readonly int $customerDeviceTokenId,
        public readonly string $title,
        public readonly string $body,
        public readonly string $route,
    ) {}

    public function handle(FcmClient $fcm): void
    {
        $device = CustomerDeviceToken::query()->find($this->customerDeviceTokenId);

        // نُسي بين الإدراج والتنفيذ — بالخروج، أو لأن مهمّةً قبله وجدته ميّتاً. لا فشل، لا شيء يُرسل.
        if ($device === null) {
            return;
        }

        $result = $fcm->send(
            deviceToken: $device->token,
            platform: $device->platform,
            title: $this->title,
            body: $this->body,
            route: $this->route,
            // لا صفَّ إشعارٍ للعميل ولا جرس، فلا رقمَ يعلّمه التطبيقُ مقروءاً ولا عددَ على الأيقونة.
            notificationId: null,
            badge: null,
        );

        // ميّتٌ نهائياً، فيُحذف الصفُّ بدل أن تفشل المهمّة: تطبيقٌ أُزيل لا يملأ `failed_jobs`.
        if ($result === FcmSendResult::TokenIsDead) {
            $device->delete();

            return;
        }

        $device->last_used_at = Carbon::now();
        $device->save();
    }
}
