<?php

declare(strict_types=1);

namespace App\Domain\Notification\DTOs;

/**
 * دفعةٌ واحدة إلى هواتف عميلٍ واحد.
 *
 * **الكلماتُ تُكتب هنا ساعةَ الحدث ولا تُخزَّن**، خلافاً لإشعارات الموظفين التي تُرسم من حمولةٍ
 * محفوظة: العميلُ لا صندوقَ بريدٍ له، فلا صفَّ يُقرأ منه لاحقاً. ما لم يصل الهاتفَ الآن لن يُعاد.
 *
 * **ولا شيءَ حسّاسٌ فيها**: تُقرأ على شاشةٍ مقفلة، فلا مبلغ ولا نصَّ رسالة — التطبيقُ يجلب
 * التفاصيل بعد اللمس.
 */
final readonly class CustomerPush
{
    /**
     * @param  string  $title  سطرٌ واحد، الخبرُ نفسه
     * @param  string  $body  سطرٌ آخر من التفصيل
     * @param  string  $route  أين يذهب اللمس في تطبيق العميل — `/orders/145` أو `/support/12`
     */
    public function __construct(
        public int $customerId,
        public string $title,
        public string $body,
        public string $route,
    ) {}
}
