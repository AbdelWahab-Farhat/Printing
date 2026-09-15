# دعاية (Dayaa) — تطبيق العميل (Flutter)

تطبيق العميل (`ly.dayaa.client`) — الوجه الذي يرى فيه الزبون طلبياته وتصاميمه وحسابه.
تطبيق الموظفين هو الجار: [../frontend](../frontend) (`ly.dayaa.app`)، والاثنان يتحدثان إلى نفس
الخادم في [../backend](../backend).

**البنية: MVVM-Clean** — الطبقات من Clean Architecture، والـ ViewModel هو الـ Cubit.

> 📐 **[RULES.md](RULES.md) هو المعيار الملزم**، وهو نسخة قواعد الجار حرفاً بحرف. اقرأه قبل
> كتابة أي كود.
>
> 📋 **[BACKLOG.md](BACKLOG.md)** يسرد ما لم يُنقل من هناك وسببه والشرط الذي يعيده.

Flutter 3.44.6 · Dart 3.12.2

## الحالة

**البنية التحتية فقط، ولا ميزة بعد.** `lib/features/` يحمل شاشة بداية فارغة تنتظر أول ميزة
حقيقية تزيحها، لأن الـ API لم يفتح بعد أي مسار موجّه للعميل — `routes/api.php` اليوم كله خلف
`can:` مبنيّ لموظف. أول عمل هنا هو قرار على الطرفين معاً.

المنقول وجاهز: الشبكة والأخطاء والتصفّح والتخزين والثيم والويدجتات المشتركة والترقيم، ومعها
١٨١ اختباراً.

## التشغيل

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # يولّد ملفات Freezed / JSON
flutter run --dart-define=FLAVOR=dev                      # تطوير
```

## البيئات (Flavours)

نكهتان فقط، ولكل واحدة ملف بيئة خاص بها. الاختيار يتم **وقت الترجمة** عبر `--dart-define`، فنسخة
release لا يمكن توجيهها إلى خادم التطوير بأي شيء وقت التشغيل:

| النكهة | الملف | الأمر |
|---|---|---|
| `prod` | `.env` | الافتراضي — بدون أي `--dart-define` |
| `dev` | `.env.dev` | `--dart-define=FLAVOR=dev` |

`.env.example` وحده مرفوع في git ويوثّق المفاتيح؛ الملفان الآخران مستثنيان لأن فيهما عناوين خوادم.
وكل ملف **يجب** أن يكون مُدرجاً تحت `assets:` في [pubspec.yaml](pubspec.yaml) — نكهة ملفها غير
محزوم تنهار عند الإقلاع لا عند البناء.

`.env.dev` يحمل مفتاحاً إضافياً `BASE_URL_ANDROID`: محاكي أندرويد لا يصل `127.0.0.1` — ذلك العنوان
هو المحاكي نفسه — فيمرّ عبر `10.0.2.2`. يُقرأ فقط في نكهة `dev`.

## البناء

```bash
flutter build apk --release --dart-define=FLAVOR=dev  # نسخة تجريبية على خادم التطوير
flutter build apk --release                           # إنتاج (prod افتراضياً)
```

⚠️ **لا تستعمل `--flavor`.** البيئة هنا `--dart-define` لا product flavor في Gradle —
[AppConfig](lib/core/config/app_config.dart) يقرؤها وقت الترجمة ليختار ملف `.env`، فلا يمكن
إقناع نسخة إنتاج بالتحدث إلى خادم التطوير. و`--flavor dev` يفشل بـ
«Task 'assembleDevRelease' not found»، لأن `android/app/build.gradle.kts` لا يعرّف أي flavor
ولا حاجة له بذلك.

**تحقّق من الخادم داخل الحزمة قبل التوزيع** — الرابط يُحرَق داخل البناء، ونسخة موجّهة إلى خادم غير
موجود تُثبَّت وتعمل ثم تفشل عند أول طلب، بلا أي رسالة تدلّ على السبب:

```bash
unzip -p build/app/outputs/flutter-apk/app-release.apk assets/flutter_assets/.env | grep BASE_URL
```

قبل أي دمج:

```bash
flutter analyze   # يجب: No issues found!
flutter test      # يجب: All tests passed!
```

## الاتصال بالـ API

| البيئة | العنوان |
|---|---|
| محاكي iOS | `http://127.0.0.1:8000/api/v1` |
| محاكي Android | `http://10.0.2.2:8000/api/v1` |

كل رد يستخدم مغلّف الـ API، ويُفكّ مرة واحدة مركزياً في
[safe_request.dart](lib/core/network/safe_request.dart):

```json
{ "status": true, "message": "تم بنجاح", "data": { } }
```

**العقد الحي هو مواصفة OpenAPI المولّدة**: شغّل الباك إند وافتح
`http://localhost:8000/docs/api` (تفاعلي) أو `/docs/api.json` (خام). إن اختلف كودنا عنها،
فالمواصفة على حق.

## أين تبدأ

| الملف | الدور |
|---|---|
| [main.dart](lib/main.dart) · [app.dart](lib/app.dart) | الإقلاع والجذر |
| [core/di/injector.dart](lib/core/di/injector.dart) | رسم الاعتماديات — كل ميزة تُسجَّل هنا |
| [core/network/safe_request.dart](lib/core/network/safe_request.dart) | الحدّ الوحيد الذي يلتقط أخطاء الشبكة |
| [../frontend/lib/features/cities/](../frontend/lib/features/cities/) | **الميزة المرجعية** — لا ميزة هنا بعد، فالنموذج يُنسَخ من هناك |

## الثيم

مولّد من [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
في [core/theme/](lib/core/theme/)، ومنقول كما هو من تطبيق الموظفين فالعلامة واحدة. يُستبدل كاملاً
عند تغيير اللوحة، ولذلك هو مستثنى من الـ linter ولا يُحرَّر يدوياً.
