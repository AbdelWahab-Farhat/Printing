# دعاية (Dayaa) — Frontend (Flutter)

تطبيق **دعاية** (`ly.dayaa.app`). **البنية: MVVM-Clean** — الطبقات من Clean Architecture، والـ ViewModel هو الـ Cubit.

> 📐 **[RULES.md](RULES.md) هو المعيار الملزم.** اقرأه قبل كتابة أي كود.

Flutter 3.44.6 · Dart 3.12.2

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

> نكهة ثالثة باسم `user` جُرّبت وأُزيلت: كانت تشير إلى نفس خادم `prod`، فكان البناءان لا يُفرَّق
> بينهما. النكهة تستحق وجودها حين تشير إلى مكان آخر فعلاً.

## البناء للنشر

الإصدار كاملاً من الماك — الويب ثم iOS ثم APK، بالنسخة نفسها من `pubspec.yaml`:

```bash
./scripts/release_all.sh                   # ويب يُنشر، iOS للمراجعة، ثم APK
./scripts/release_all.sh --cancel-pending  # نسخةٌ سابقة عالقة في المراجعة: تُسحب ثم تُرسل هذه
./scripts/release_all.sh --upload-only     # iOS إلى TestFlight فقط
./scripts/release_all.sh --from ios        # استئنافٌ بعد فشل — السكربت يطبع الأمر بنفسه
```

يفحص كلَّ ما قد يُفشل أيَّ مرحلة قبل أن يُنشر شيء (رفعُ الويب، مفتاحُ App Store Connect، ملاحظاتُ
الإصدار، حالةُ النسخة لدى Apple). **وإن كان في `frontend/` ما لم يُثبَّت، يبني من نسخةٍ نظيفة لـHEAD**
في مجلّدٍ مؤقّت — الشجرةُ مشتركة، وما لم يُثبَّت ليس من الإصدار. `--in-place` يبني من الشجرة كما هي.

أو APK وحده:

```bash
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod        # للتوزيع المباشر
flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod  # لـGoogle Play
```

يخرج الـ APK في `build/app/outputs/flutter-apk/app-prod-release.apk` (و`release_all.sh` —
عبر `scripts/build_apk.sh` — يفحصه وينسخه إلى `~/Desktop/Dayaa-Staff-<النسخة>-prod.apk`).

**تحقّق من الخادم داخل الحزمة قبل التوزيع** — الرابط يُحرَق داخل البناء، ونسخة موجّهة إلى خادم غير
موجود تُثبَّت وتعمل ثم تفشل عند أول طلب، بلا أي رسالة تدلّ على السبب:

```bash
unzip -p build/app/outputs/flutter-apk/app-prod-release.apk assets/flutter_assets/.env | grep BASE_URL
```

### التثبيت على الجهاز

```bash
adb devices                                                         # تأكد أن الجهاز متصل
adb install -r build/app/outputs/flutter-apk/app-prod-release.apk   # -r يستبدل نسخة قائمة
```

أو انسخ ملف الـ APK إلى الهاتف وافتحه (يتطلّب السماح بالتثبيت من مصادر غير المتجر).

ولتشغيل نسخة release موصولة بالحاسوب مباشرة:

```bash
flutter run --release
```

## الشعار

شعار واحد — [assets/images/logo.png](assets/images/logo.png) — خلف ثلاثة أشياء: أيقونة التطبيق،
والشاشة التي يرسمها النظام أثناء الإقلاع، والعلامة على [SplashPage](lib/features/splash/presentation/views/splash_page.dart).
بعد تغييره:

```bash
python3 tool/make_branding_assets.py   # النسخ المبطّنة في assets/branding/
dart run flutter_launcher_icons        # أيقونات android/ و ios/
dart run flutter_native_splash:create  # شاشة الإقلاع
```

الإعدادات وأسبابها في آخر [pubspec.yaml](pubspec.yaml)، والمقاسات وأسبابها في
[tool/make_branding_assets.py](tool/make_branding_assets.py). و`assets/branding/` **ليست** ضمن
`assets:` — مدخلات بناء لا يحمّلها التطبيق.

## البناء

```bash
flutter build apk --release --flavor dev --dart-define=FLAVOR=dev    # تجريبية على خادم التطوير
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod  # إنتاج
```

⚠️ **اثنان مستقلّان، ويُمرَّران معاً.** `--flavor` نكهة Gradle في
[android/app/build.gradle.kts](android/app/build.gradle.kts): تختار الحزمة (`ly.dayaa.app` أو
`ly.dayaa.app.dev`، فتُنصَّبان جنباً إلى جنب) واسمها وأيقونتها. و`--dart-define=FLAVOR` يختار ملف
`.env`، أي الخادم — [AppConfig](lib/core/config/app_config.dart) يقرؤه وقت الترجمة، فلا يمكن
إقناع نسخة إنتاج بالتحدث إلى خادم التطوير. أحدهما بلا الآخر يعطي حزمةً لا تطابق خادمها.

⚠️ **التوقيع بمفتاح debug** (`signingConfigs.getByName("debug")`)، ومفتاح debug لكل جهازٍ مختلف:
APK مبنيٌّ على جهازٍ آخر لا يُنصَّب فوق نسخةٍ قائمة إلا بحذفها أولاً.

قبل أي دمج:

```bash
flutter analyze   # يجب: No issues found!
flutter test      # يجب: All tests passed!
```

## الاتصال بالـ API

التطبيق يتحدث مع Laravel في [../backend/](../backend/).

| البيئة | العنوان |
|---|---|
| محاكي iOS | `http://127.0.0.1:8000/api/v1` |
| محاكي Android | `http://10.0.2.2:8000/api/v1` |

[AppConfig](lib/core/config/app_config.dart) يختار بينهما تلقائياً — محاكي أندرويد لا يصل إلى
`127.0.0.1` الخاص بالمضيف.

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
| [features/cities/](lib/features/cities/) | **الميزة المرجعية** — انسخ بنيتها لأي ميزة جديدة |

## الثيم

مولّد من [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
في [core/theme/](lib/core/theme/). يُستبدل كاملاً عند تغيير اللوحة، ولذلك هو مستثنى من الـ linter
ولا يُحرَّر يدوياً.

## البيئات

`.env` (إنتاج) و `.env.dev` (تطوير) **غير مرفوعين إلى git**. كل مفتاح جديد يُضاف إلى
`.env.example` حتى يعرف بقية الفريق أنه موجود.
