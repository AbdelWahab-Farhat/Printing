<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Notification\DTOs\CustomerPush;
use App\Domain\Notification\NotificationService;
use App\Domain\Order\Enums\CustomerOrderStage;
use App\Domain\Order\Events\OrderStatusChanged;
use App\Domain\Order\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يُخبر العميلَ على هاتفه أن طلبيته انتقلت — في المراحل التي تعنيه وحدها.
 *
 * ### بالمرحلة لا بالحالة
 *
 * العميلُ يرى مراحلَ لا حالات ({@see CustomerOrderStage})، فالقرارُ يُتّخذ بلغته:
 * انتقالٌ تبقى فيه المرحلةُ كما هي — من المطبعة إلى ورشةٍ خارجية، من «جاهزة» إلى «استلام مكتب»، من
 * «تم التسليم» إلى «تم التسوية» — لا يغيّر شيئاً على شاشته، فلا يُقال له شيء.
 *
 * ### ما يُقال، ولماذا هذا دون غيره
 *
 * القاعدة: **يُدفع ما يغيّر ما سيفعله العميل أو ما ينتظره**، ويسكت ما هو تقدّمٌ داخليٌّ يراه في
 * التطبيق إن فتحه.
 *
 * - **قبلنا طلبيتك** — من «بانتظار المراجعة» إلى «قيد التجهيز» وحدها. هو الجواب الذي ينتظره منذ
 *   أرسل الطلب. أما العودةُ إلى «قيد التجهيز» من طريقٍ آخر (من التصميم إلى الطباعة) فتقدّمٌ داخليٌّ
 *   صامت، و«قبلنا» فيها كذب.
 * - **طلبيتك جاهزة** — قد يُطلب منه أن يأتي، أو أن ينتظر اتصالنا.
 * - **طلبيتك في الطريق إليك** — ليكون حيث يصل المندوب ومعه المبلغ.
 * - **رجعت طلبيتك إلينا** — شيءٌ لم يسر كما يجب، وسنتواصل معه.
 * - **أُلغيت طلبيتك** — نهايةٌ لا يجوز أن يكتشفها صدفة.
 * - **تعذّر قبول طلبيتك** — جوابُ طلبه، وإن لم يكن الذي أراده.
 *
 * والصامتة:
 *
 * - **بانتظار المراجعة** — هو الذي أرسل الطلب، أو هو تراجعٌ عن رفضٍ لم يُسأل فيه شيئاً.
 * - **قيد التصميم** و**قيد الإنتاج** — تقدّمٌ لا يُطلب فيه منه شيء، ويراه في التطبيق.
 * - **تم الاستلام** — الطردُ في يده، فلا يُخبَر بما يعرفه.
 *
 * `match` بلا `default`: مرحلةٌ تُضاف يوماً ترمي `UnhandledMatchError` في الاختبارات حتى يقرّر أحدٌ
 * أهي خبرٌ للعميل أم لا.
 *
 * ### النصّ
 *
 * رقمُ الطلبية ثم سطرُ المرحلة (`hint()`)، أو الرقمُ وحده حين لا سطرَ لها. **الرقمُ عارٍ**: لا
 * «طلبية» ولا «#» قبله — قاعدةٌ في تطبيق العميل كلّه. ولا مبلغَ ولا شيءَ حسّاس: الدفعُ يُقرأ على
 * شاشةٍ مقفلة.
 *
 * ### مُدرَجٌ في الطابور، وبعد الإيداع
 *
 * كجيرانه وللسبب نفسه ({@see NotifyWhenOrderEntersShortage}): دفعٌ فاشلٌ لا يُرجع طلبيةً سُلّمت،
 * وخبرٌ عن معاملةٍ تراجعت لا يُسحب من هاتف أحد.
 */
final class NotifyCustomerWhenOrderStageChanges implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(OrderStatusChanged $event): void
    {
        $from = CustomerOrderStage::forStatus($event->from);
        $to = CustomerOrderStage::forStatus($event->to);

        if ($from === $to) {
            return;
        }

        $title = $this->titleFor($from, $to);

        if ($title === null) {
            return;
        }

        $order = Order::query()->find($event->orderId);

        // قد تكون حُذفت بين الإيداع وتنفيذ المهمّة، ولا صاحبَ لطلبيةٍ بلا عميل.
        if ($order === null || $order->customer_id === null) {
            return;
        }

        $code = (string) $order->code;
        $hint = $to->hint();

        $this->notifications->pushToCustomer(new CustomerPush(
            customerId: (int) $order->customer_id,
            title: $title,
            body: $hint === null ? $code : "{$code} · {$hint}",
            route: '/orders/'.$order->getKey(),
        ));
    }

    /**
     * عنوانُ الدفعة، أو `null` حين لا يُقال شيء. انظر تعليقَ الصنف للأسباب.
     */
    private function titleFor(CustomerOrderStage $from, CustomerOrderStage $to): ?string
    {
        return match ($to) {
            CustomerOrderStage::Preparing => $from === CustomerOrderStage::UnderReview ? 'قبلنا طلبيتك' : null,
            CustomerOrderStage::Ready => 'طلبيتك جاهزة',
            CustomerOrderStage::OnTheWay => 'طلبيتك في الطريق إليك',
            CustomerOrderStage::Returned => 'رجعت طلبيتك إلينا',
            CustomerOrderStage::Cancelled => 'أُلغيت طلبيتك',
            CustomerOrderStage::Rejected => 'تعذّر قبول طلبيتك',

            CustomerOrderStage::UnderReview,
            CustomerOrderStage::Designing,
            CustomerOrderStage::Producing,
            CustomerOrderStage::Delivered => null,
        };
    }
}
