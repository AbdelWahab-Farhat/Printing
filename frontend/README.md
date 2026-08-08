# Printing — Frontend (Flutter)

تطبيق Printing. **البنية: MVVM-Clean** — الطبقات من Clean Architecture، والـ ViewModel هو الـ Cubit.

> 📐 **[RULES.md](RULES.md) هو المعيار الملزم.** اقرأه قبل كتابة أي كود.

Flutter 3.44.6 · Dart 3.12.2

## التشغيل

```bash
flutter pub get
dart run build_runner build          # يولّد ملفات Freezed / JSON
flutter run --dart-define=FLAVOR=dev # تطوير
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
flutter build apk --release --dart-define=FLAVOR=dev  # نسخة تجريبية على خادم التطوير
flutter build apk --release                           # إنتاج (prod افتراضياً)
```

⚠️ **لا تستعمل `--flavor`.** البيئة هنا `--dart-define` لا product flavor في Gradle —
[AppConfig](lib/core/config/app_config.dart) يقرؤها وقت الترجمة ليختار ملف `.env`، فلا يمكن
إقناع نسخة إنتاج بالتحدث إلى خادم التطوير. و`--flavor dev` يفشل بـ
«Task 'assembleDevRelease' not found»، لأن `android/app/build.gradle.kts` لا يعرّف أي flavor
ولا حاجة له بذلك.

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
