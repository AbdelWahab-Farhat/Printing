<?php

declare(strict_types=1);

namespace App\Domain\Notification\Channels;

use App\Domain\Notification\DTOs\CustomerPush;
use App\Domain\Notification\Jobs\DeliverCustomerPush;
use App\Domain\Notification\Models\CustomerDeviceToken;
use App\Domain\Notification\Support\FcmClient;
use Illuminate\Database\Eloquent\Builder;

/**
 * يوقظ هواتفَ عميلٍ واحد — نظيرُ {@see PushChannel} في تطبيق العميل.
 *
 * **لا يُطبّق `NotificationChannel`، وعن قصد.** ذاك العقد يأخذ صفَّ إشعارٍ وقائمةَ موظفين، والعميلُ
 * لا صفَّ له ولا جرس: الدفعُ هنا هو الإشعارُ كلّه، والكلماتُ تسافر في المهمّة نفسها.
 *
 * **مهمّةٌ لكل جهاز** كنظيره: رمزٌ ميّت يعيد المحاولةَ ويفشل وحده، ولا يُسقط معه هاتفَ العميل الآخر.
 *
 * **ولا شيءَ هنا مضمونُ الوصول، ولا شيءَ يعتمد عليه.** كلُّ ما يقوله الدفعُ يراه العميلُ في التطبيق
 * حين يفتحه — مرحلةُ الطلبية وشارةُ الدعم — فهاتفٌ مطفأ أو مشروعُ Firebase لم يُضبط بعدُ يعني
 * أنه يعرف الخبرَ متأخراً، لا أنه لا يعرفه.
 */
final readonly class CustomerPushChannel
{
    /**
     * @param  array<string, mixed>  $config  كتلة `services.fcm`
     */
    public function __construct(private array $config) {}

    public function deliver(CustomerPush $push): void
    {
        // قبل أيّ استعلام، وللسبب المكتوب على PushChannel::isConfigured(): بلا هذا يصير كلُّ دفعٍ
        // على خادمٍ لم يُضبط بعدُ مهمّةً تفشل ثلاث مرات وتدفن الأعطالَ الحقيقية في `failed_jobs`.
        if (! FcmClient::isConfigured($this->config)) {
            return;
        }

        CustomerDeviceToken::query()
            ->where('customer_id', $push->customerId)
            // **العميلُ المحذوفُ والمعطَّلُ لا يُوقَظان، والغائبُ كذلك** — في الاستعلام نفسه لا
            // بقراءةٍ قبله: `whereHas` يمرّ بنطاق SoftDeletes على العميل، فالمحذوفُ يسقط وحده،
            // والمعطَّلُ بالشرط. حسابٌ أوقفه المحل لا يتلقّى أخبارَه، ويعود الدفعُ إن أُعيد تفعيله
            // لأن أجهزته باقية.
            ->whereHas('customer', fn (Builder $customer) => $customer->where('is_active', true))
            ->pluck('id')
            ->each(fn ($deviceId) => DeliverCustomerPush::dispatch(
                (int) $deviceId,
                $push->title,
                $push->body,
                $push->route,
            ));
    }
}
