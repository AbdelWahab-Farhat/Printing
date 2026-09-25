<?php

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| قنوات البثّ الحيّ
|--------------------------------------------------------------------------
| من يستمع إلى ماذا. كل قناةٍ هنا **خاصة** (`private-…`): لا يدخلها مقبسٌ إلا بتوقيعٍ من هذا
| الخادم، ويوقّع بابا `broadcasting/auth` — بابُ الموظفين في routes/api.php وبابُ العملاء في
| routes/api_client.php — بعد أن يسأل كلُّ باب حارسَه.
|
| **`guards` على كل قناة، وليس زينة.** هو ما يجعل قناةَ المكتب تسأل حارسَ الموظفين وحده، فلا
| يفتحها رمزُ عميلٍ مهما كان صالحاً عند حارسه — الجدار نفسه الذي يفصل التطبيقين في
| config/auth.php. وجوابُ الدالة `false` يصير ٤٠٣.
|
| يُحمَّل هذا الملف من AppServiceProvider بعد الإقلاع، لا بـ`withRouting(channels: …)`: تلك
| تسجّل معه باباً ثالثاً `/broadcasting/auth` تحت مجموعة `web` وجلساتها — بابٌ لا يستعمله
| تطبيقٌ من تطبيقَينا، ولا يُترك بابٌ مفتوح لأنه لا يستعمله أحد.
*/

/*
 * مكتبُ الدعم: كلُّ تذكرةٍ تتغيّر — رسالة، إسناد، إغلاق، قراءة. يسمعها من يقرأ الطابور، أي
 * صاحبُ `support.view` — الإذن نفسه الذي يحرس `GET support/tickets`.
 */
Broadcast::channel(
    'support.desk',
    fn ($user): bool => $user instanceof User && $user->can(PermissionName::ViewSupportTickets->value),
    ['guards' => ['sanctum']],
);

/*
 * قناةُ العميل نفسه، وما يخصّه وحده: ردودُ المحل على تذاكره اليوم، وغيرُها غداً باسم حدثٍ جديد
 * على القناة ذاتها.
 *
 * **يُقارن الرقم نصّاً.** قناةٌ اسمها `customers.abc` لا تصل إلى نوعٍ رقميٍّ فترمي خطأً ٥٠٠ —
 * هي ببساطة ليست قناةَ هذا العميل.
 */
Broadcast::channel(
    'customers.{customerId}',
    fn ($customer, string $customerId): bool => $customer instanceof Customer
        && (string) $customer->getKey() === $customerId,
    ['guards' => ['customer']],
);
