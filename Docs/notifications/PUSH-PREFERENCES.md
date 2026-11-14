# إشعارات الهاتف لكل موظف

> يقرّر المدير، لكل موظف، أيُّ الإشعارات الجماعية توقظ هاتفه. الجرس داخل التطبيق لا يُطفأ أبداً.
> الفرع `notification-preferences`، ٢٠٢٦-١١-١٣. مبنيٌّ على
> [NOTIFICATIONS-BACKEND-CHANGES.md](NOTIFICATIONS-BACKEND-CHANGES.md) و
> [ORDER-STATUS-NOTIFICATIONS.md](ORDER-STATUS-NOTIFICATIONS.md).

---

## ١. لماذا

كان الإعداد الوحيد مفتاح «تفعيل الإشعارات» على الهاتف: للجهاز لا للحساب، والكلُّ أو لا شيء. وأكثر
الضجيج من الإشعارات الجماعية — `order.status` وحده يصل إلى كل من يملك `orders.view` في عشر حالات.
وهذا بالضبط ما توقّعه بند [BACKLOG](../BACKLOG.md) «توجيه إشعار حالة الطلبية»: «موظفون يُطفئون
الإشعارات».

---

## ٢. القرارات (المالك، ٢٠٢٦-١١-١٣)

| | القرار |
|---|---|
| مَن يعدّل | **المدير وحده** — `users.manage`، من شاشة الموظف. الموظف لا يرى الصفحة لنفسه |
| ماذا يُطفأ | **دفعُ الهاتف وحده**. الجرس يمتلئ دائماً |
| حالة الطلبية | **مفتاحٌ لكل حالة** تُشعِر — يبقى «جاهزة» ويُطفأ «تم التسوية» |
| افتراضيات الأدوار | **لا**. الكلُّ مفعَّل، والتغيير لكل موظف |
| ساعات الهدوء | **لا**، الآن |

---

## ٣. ما الذي يُطفأ وما الذي لا يُطفأ

**يُطفأ ما يصل إلى جماعة، لا ما يصل إلى شخصٍ باسمه.** الفحص في `PublishNotification` على نوع
الجمهور: `AudienceKind::Permission` وحده يمرّ على الإعداد. فما أُسنِد إلى الموظف — تذكرةٌ على مكتبه،
تذكرةُ تصميمٍ أُعطيت له، تذكرةٌ داخلية، محفظته — يصل إلى هاتفه دائماً، لأن إطفاءه يكسر التسليم نفسه.

الأنواع السبعة التي تظهر لها مفاتيح (`GroupNotification`):

| النوع | الجماعة |
|---|---|
| `order.status` — مفتاح لكل حالة تُشعِر | `orders.view` |
| `order.shortage` | `orders.view` |
| `order.requested` | `orders.manage` |
| `order.deposit_chosen` | `orders.manage` |
| `support.customer_message` — الطابور فقط | `support.manage` |
| `design_ticket.assigned` — المجمَّع فقط | `design_tickets.accept` |
| `employee_wallet.salaries_posted` | `users.wallet.view` |

**الإعلانات اليدوية لا تُطفأ**: ليست `GroupNotification`، فتصل دائماً.

حالاتُ `order.status` التي لها مفاتيح هي نفسها التي تُشعِر — `NotifyWhenOrderStatusChanges::isWorthABell()`،
صارت `public static` ليقرأها `OrderReachedStatus::pushScopes()`. قائمةٌ واحدة تُقرأ مرّتين.

**الصفحة لا تعرض إلا ما يصل الموظفَ فعلاً**: يُسأل الـ Gate عن `groupPermission()` للموظف المعروض،
فلا يرى المصمم صفوف الطلبيات.

---

## ٤. التخزين

جدول `notification_preferences`: `user_id`، `type`، `scope`، `push`.

- **متفرّق.** لا صفَّ = مفعَّل. فلا يتغيّر هاتفُ أحدٍ يوم النشر، ونوعٌ يُضاف العام القادم لا يحتاج صفاً
  ولا هجرة.
- `scope` نصٌّ فارغ لا `NULL` للنوع ذي المفتاح الواحد، كي يصمد الفهرس الفريد في Postgres
  (`(user_id, type, scope) WHERE deleted_at IS NULL`).
- **يُقلب في مكانه ولا يُحذف**، فيقرأ سجلُّ التغييرات مفتاحاً يتحرّك لا صفوفاً تظهر وتختفي. والصفُّ
  الأول الذي يقول «مفعَّل» لا يُكتب: هو الافتراضي.
- **مُدقَّق** (`notification_preference` في `AuditSubject`)، بخلاف بقية سياق الإشعارات: هذا قرارُ
  شخصٍ في هاتف شخصٍ آخر، و«مَن أطفأ إشعارات التسوية عن فلان؟» يحتاج جواباً.

---

## ٥. الواجهة

| | |
|---|---|
| `GET /users/{user}/notification-preferences` | المفاتيح، بترتيب الكتالوج — `users.manage` |
| `PUT /users/{user}/notification-preferences` | `{type, scope?, push}` يقلب مفتاحاً ويُرجع المفاتيح بعده — `users.manage` |

نوعٌ لا مفتاح له (إعلان، تذكرة داخلية)، أو حالةٌ لا تُشعِر، أو `scope` على نوعٍ بلا حالات → **422**.

في التطبيق: شاشة الموظف ← الزر العائم ← «إشعارات الهاتف» (`/employees/{id}/notifications`).
المفتاح يتحرّك عند اللمس ويرجع إن رفض الخادم — هو وحده، لا مفتاحٌ لُمس أثناء الانتظار.

مفتاح «تفعيل الإشعارات» في الإعدادات باقٍ كما هو: ذاك عن **هذا الجهاز**، وهذا عن **الحساب** على كل
جهاز.

---

## ٦. خارج النطاق

- تعديل الموظف لإعداده بنفسه، وإطفاء الجرس، وافتراضيات الأدوار، وساعات الهدوء — §٢.
- `Docs/openapi.json` لم يُعَد توليده: الملف على `main` متأخّر كثيراً، وإعادة توليده تكتب ~٤٧ ألف
  سطر لا علاقة لها بهذا التغيير. يُعاد في التزامٍ وحده.

---

## ٧. النشر

هجرةٌ واحدة تُنشئ جدولاً جديداً، بلا ملء ولا لمسٍ لصفٍّ قائم. لا متغيّرات بيئة. التطبيقُ يحتاج إصداراً
لتظهر الصفحة؛ والخادمُ وحده آمنٌ قبله، فلا صفوف تُكتب حتى يستعمل أحدٌ الصفحة.

---

## ٨. الملفات

**الخادم**
- `Contracts/GroupNotification.php`، `Definitions/Concerns/OneSwitch.php` — والتعريفات السبعة تطبّقه
- `Actions/PublishNotification.php` — `pushRecipients()`
- `Queries/MutedPushQuery.php`، `Queries/PushPreferencesQuery.php`، `Actions/SetPushPreference.php`
- `Models/NotificationPreference.php`، الهجرة `2026_11_13_100000_create_notification_preferences_table`
- `NotificationPreferenceController`، `SetPushPreferenceRequest`، `PushPreferenceGroupResource`
- الاختبارات: `tests/Feature/Notifications/PushPreferenceTest.php`

**التطبيق**
- `features/notifications/models/push_preference.dart`
- `features/notifications/presentation/{viewmodel/push_preferences_cubit.dart, views/push_preferences_page.dart}`
- `GetPushPreferences`، `SetPushPreference`، ودخولٌ في `employee_detail_page.dart`
- الاختبارات: `test/features/notifications/push_preference*_test.dart`، وحالتان في `employee_detail_page_test.dart`
