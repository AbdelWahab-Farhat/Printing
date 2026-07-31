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
