# Printing — Flutter Rules

> المعيار الملزم لكيفية بناء تطبيق Printing.
> **كود نظيف · بنية واضحة · قرارات مقصودة · كل سلوك له اختبار.**
>
> [../backend/CLAUDE.md](../backend/CLAUDE.md) يحمل القواعد العامة لأي مستودع.
> **هذا الملف يحمل قواعد الـ Flutter، ويغلب عند التعارض.** كل المسارات نسبية إلى `frontend/`.

---

## 0. الخمس قواعد الأهم

إن لم تتذكر شيئاً غيرها:

1. **الـ Cubit ينادي UseCase، والـ UseCase ينادي Repository مجرّد.** لا Dio ولا `*Impl` فوق طبقة الـ repositories. → [§2](#2-البنية-المعمارية)
2. **`Freezed` لكل State ولكل Model.** الـ State اتحاد مغلق (sealed union)، لا حقول nullable متجاورة. → [§4](#4-إدارة-الحالة)
3. **`try`/`catch` ممنوع خارج [safe_request.dart](lib/core/network/safe_request.dart).** الأخطاء تعود كـ `Either<Failure, T>`. → [§5](#5-الأخطاء)
4. **لا منطق أعمال داخل Widget.** الـ Cubit يقرر، الـ Widget يرسم — و`setState` لحالة بصرية بحتة في ويدجت واحد مقبول. → [§4](#4-إدارة-الحالة)
5. **`flutter analyze` نظيف + الاختبارات خضراء** شرط الدمج. → [§9](#9-الجودة-والتحقق)

---

## 1. المنظومة

| الطبقة | الاختيار |
|---|---|
| SDK | Flutter 3.44.6 · Dart 3.12.2 |
| الحالة | **Cubit** (`flutter_bloc`) — لا BLoC كامل إلا عند الحاجة لتدفق أحداث حقيقي |
| النماذج | **Freezed** + `json_serializable` |
| الشبكة | **Dio** — عميل واحد مسجّل في `GetIt` |
| الحقن | **GetIt** عبر [Injector](lib/core/di/injector.dart) |
| التنقل | **GoRouter** فقط |
| النتائج | `Either<Failure, T>` من `dartz` |
| القياس | `flutter_screenutil` — تصميم مرجعي `430×932` |
| الأسرار | `flutter_secure_storage` للتوكن، `shared_preferences` لما عداه |

### الأوامر

```bash
flutter run --dart-define=FLAVOR=dev        # تطوير
flutter run                                  # إنتاج (prod افتراضياً)
dart run build_runner build                  # بعد أي تعديل على Freezed/JSON
dart run build_runner watch                  # أثناء العمل المتواصل
flutter analyze                              # يجب أن يخرج "No issues found!"
flutter test                                 # كل الاختبارات
```

---

## 2. البنية المعمارية

**MVVM-Clean.** الطبقات من Clean Architecture، والـ ViewModel هو الـ Cubit.

```text
lib/
├── core/                     المشترك بين كل الميزات
│   ├── config/               AppConfig — الـ flavor و baseUrl
│   ├── di/                   Injector — الرسم البياني للاعتماديات
│   ├── error/                Failure — اتحاد الأخطاء
│   ├── network/              Dio، safeRequest، الـ endpoints، Paginated
│   ├── router/               AppRouter + Routes
│   ├── storage/              TokenStorage
│   ├── theme/                مولّد من Material Theme Builder — لا يُحرَّر يدوياً
│   ├── utils/                Validators، الامتدادات
│   └── widgets/              الويدجتات المشتركة (Snackbar، Dialog، الحقول)
│
└── features/<feature>/
    ├── models/               Freezed + JSON — صنف واحد لكل شيء
    ├── repositories/
    │   ├── x_repository.dart      العقد المجرد (abstract interface class)
    │   └── x_repository_impl.dart التنفيذ — ينادي Dio عبر safeRequest
    ├── usecases/             فعل واحد، صنف واحد، دالة `call`
    └── presentation/
        ├── viewmodel/        الـ Cubit + الـ State
        ├── views/            الشاشات
        └── widgets/          ويدجتات هذه الميزة فقط
```

### قاعدة الاتجاه — الأهم في هذا الملف

```text
presentation  ──►  usecases  ──►  repository (مجرد)  ◄──  repository_impl
```

- **الـ Cubit ينادي UseCase**، والـ UseCase ينادي **العقد المجرد** لا التنفيذ.
- **لا أحد فوق طبقة الـ repositories يعرف `*Impl` ولا يستورد `dio`.** الـ `Impl` معروف لـ [Injector](lib/core/di/injector.dart) وحده.
- **`models/` مشتركة** — الـ Cubit والـ Widget يقرآن `City` مباشرة.

**الاختبار العملي:** لو استُبدل Dio بـ GraphQL غداً، يجب أن يتغير `*_repository_impl.dart` وحده.

### لماذا لا يوجد `domain/` ولا `datasources/`؟

كان هناك، وأُزيلا بعد أن تبيّن أنهما لا يشتريان شيئاً في هذا المشروع:

**`Entity` منفصل عن `Model`** كان مبرَّراً بأنه «الفاصل الذي يمنع تسمية في Laravel من الوصول إلى الويدجت» — لكن **`@JsonKey` هو ذلك الفاصل بالفعل**. حين يعيد الباك إند تسمية `delivery_price` يتغير سطر واحد في [city.dart](lib/features/cities/models/city.dart)، تماماً كما كان. الصنف الثاني و`toEntity()` لكل حقل كانا ملفاً إضافياً وتحويلاً يجب إبقاؤه متزامناً، مقابل صفر حماية إضافية.

**`DataSource` منفصل عن `RepositoryImpl`** كان صنفاً يمرّر لصنف. لمصدر بيانات واحد، هذا ملف إضافي تفتحه في طريقك إلى الطلب.

> **متى يعودان؟** الـ DataSource يستحق الوجود يوم يظهر **مصدر ثانٍ** بجانب الشبكة — كاش محلي مثلاً — فيصير `Impl` هو من يوفّق بينهما. والـ Entity المنفصل يستحقه يوم يختلف **شكل المجال عن شكل الـ API** اختلافاً حقيقياً (حقل مُركّب من ثلاثة، أو نوع من مصدرين). العقد المجرد يعني أن أياً منهما تغييرٌ تحت السطر، بلا أثر فوقه.

### ما بقي، وسبب بقائه

- **العقد المجرد (`abstract interface class`)** — هذا ما يجعل اختبار الـ Cubit سطراً واحداً بلا Dio ولا Keychain. أغلى ما في الطبقات، وأرخصها.
- **UseCase = فعل واحد** (`GetCities`, `Login`) مع `call` واحدة. يبدو رقيقاً اليوم، وهو المكان الذي تحطّ فيه قاعدة العمل حين تظهر بدل أن تُنسخ في كل Cubit.

### القواعد

- **لا يستورد Widget ولا Cubit من `*_repository_impl.dart`** — ولا `dio` package.
- **`abstract interface class`** لعقود الـ repositories — يمنع التوريث غير المقصود.
- **الويدجت المشترك في `core/widgets/`**، والخاص بالميزة في `features/<f>/presentation/widgets/`.
- **الاستيراد بـ `package:`** دائماً — `always_use_package_imports` مفعّل، لأن `../../../` يخفي كسر الطبقات.

---

## 3. النماذج والتوليد

### Freezed 3 — الصياغة

```dart
// كيان أو نموذج (منشئ واحد) → abstract
@freezed
abstract class City with _$City {
  const factory City({required int id, required String name}) = _City;
  const City._();                      // مطلوب لإضافة getters/methods
  bool get hasPin => latitude != null;
}

// اتحاد (منشئات متعددة) → sealed
@freezed
sealed class CitiesState with _$CitiesState {
  const factory CitiesState.loading() = CitiesLoading;
}
```

### القواعد

- **بعد أي تعديل: `dart run build_runner build`.** الملفات `.freezed.dart` و `.g.dart` **لا تُحرَّر يدوياً** ولا تُراجَع.
- **`@JsonKey(name: 'snake_case')`** لكل حقل يختلف اسمه عن الـ API. الـ Model وحده يعرف `snake_case`.
- **المال نص (`String`) لا `double`.** `'15.00'` كما يرسله الخادم. الـ `double` لا يجمع النقود جمعاً صحيحاً.
- **`null` ≠ صفر.** `deliveryPrice == null` يعني «لم يُحدد السعر»، و `'0.00'` يعني «مجاني». اعرضهما مختلفَين.
- **الإحداثيات `double?`** — كلاهما أو لا شيء.

---

## 4. إدارة الحالة

### Cubit فقط، و State اتحاد Freezed

```dart
@freezed
sealed class CitiesState with _$CitiesState {
  const factory CitiesState.initial() = CitiesInitial;
  const factory CitiesState.loading() = CitiesLoading;
  const factory CitiesState.loaded({required Paginated<City> page}) = CitiesLoaded;
  const factory CitiesState.failure(Failure failure) = CitiesFailure;
}
```

**لماذا اتحاد وليس صنفاً بحقول nullable؟** الشكل الآخر يسمح بـ `isLoading: true` و `error != null` معاً — حالة لا رسم لها، وهي بالضبط كيف تعلق دائرة التحميل فوق رسالة خطأ. هنا المترجم يرفض تكوينها، و `switch` في الشاشة شامل: تضيف حالة، فتتوقف كل الشاشات عن الترجمة حتى تقول ماذا ترسم.

### في الـ View

```dart
BlocBuilder<CitiesCubit, CitiesState>(
  builder: (context, state) => switch (state) {
    CitiesInitial() || CitiesLoading() => const LoadingView(),
    CitiesFailure(:final failure)      => ErrorView(message: failure.message),
    CitiesLoaded(:final page)          => CityList(cities: page.items),
  },
)
```

### القواعد الملزمة

1. **لا `setState` لمنطق أعمال.** مقبول فقط لحالة بصرية بحتة داخل Widget واحد (AnimationController، فتح/إغلاق قائمة). أي شيء يأتي من الشبكة → Cubit.
2. **`if (isClosed) return;` قبل كل `emit` بعد `await`.** الشاشة قد تُغلق والطلب في الطريق، والـ emit في Cubit مغلق يرمي.
3. **الـ Cubit لا يستورد `material.dart`.** لا `BuildContext`، لا `Navigator`، لا `ScaffoldMessenger`. الـ Cubit الذي يعرف الـ context لم يعد قابلاً للاختبار بلا شجرة ويدجتات.
4. **حماية من الردود المتأخرة**: عدّاد `_requestId` — رد بطيء لبحث «طر» يجب ألا يمسح نتائج «طرابلس» الأحدث. انظر [cities_cubit.dart](lib/features/cities/presentation/viewmodel/cities_cubit.dart).
5. **البحث بـ debounce** (350ms) — لا طلب لكل حرف.
6. **فشل صفحة إضافية لا يمسح ما هو معروض.** خسارة قائمة تعمل لأن الصفحة الرابعة فشلت هي الإجابة الأسوأ.

### التسجيل في GetIt

| النوع | لماذا |
|---|---|
| `registerSingleton` | ما يجب أن يوجد قبل `runApp` — Dio، prefs |
| `registerLazySingleton` | Repositories، UseCases، Cubits على مستوى التطبيق |
| `registerFactory` | **Cubits الشاشات** — نسخة جديدة لكل شاشة |

⚠️ **Cubit شاشة مسجَّل كـ singleton هو الخطأ الكلاسيكي**: `close()` في أول شاشة يترك كل ما بعدها يبعث في تيار ميت.

---

## 5. الأخطاء

> **ارمِ ولا تلتقط.** لا يوجد `try`/`catch` خارج [safe_request.dart](lib/core/network/safe_request.dart).

كل ما تحت ذلك الخط يرمي، وكل ما فوقه يستقبل `Either`. الشاشة العالقة على دائرة تحميل بلا رسالة سببها دائماً `catch` أضافه أحدهم لأنه «لن يحدث».

```dart
final result = await _getCities();
result.fold(
  (failure) => emit(CitiesState.failure(failure)),
  (page)    => emit(CitiesState.loaded(page: page)),
);
```

### أنواع الفشل

| النوع | المعنى | ماذا تفعل الواجهة |
|---|---|---|
| `Failure.network` | **الخادم لم يجب إطلاقاً** | «أعد المحاولة» — لكن احذر مع الطلبات غير المتكررة |
| `Failure.server` | الخادم أجاب ورفض | اعرض رسالته العربية + `fieldErrors` تحت الحقول |
| `Failure.unauthorized` | 401 — الجلسة انتهت | الـ interceptor يمسح التوكن ويعيد التوجيه |
| `Failure.forbidden` | 403 — لا صلاحية | رسالة، **ولا تسجيل خروج** |
| `Failure.unexpected` | خطأ منّا (parse) | رسالة عامة |

⚠️ **`network` مقصود فصله**: يعني أن الطلب قد يكون وصل أو لا. إعادة إرسال «إنشاء طلبية» هنا قد تُنشئها مرتين.

### الرسائل

- **رسالة الخادم العربية تُعرض كما هي.** استبدالها بـ «حدث خطأ» يرمي معلومة كان الخادم قد تعب في صياغتها.
- **`errors` من Laravel تُعرض تحت حقولها**، لا كـ toast واحد — وهذا سبب إرسالها منفصلة أصلاً.

---

## 6. الشبكة

1. **لا URL مكتوب في مكانه.** كل مسار في [api_endpoints.dart](lib/core/network/api_endpoints.dart).
2. **`safeRequest` / `safePaginatedRequest` / `safeCommand`** — لا `dio.get` عارٍ.
3. **مغلّف واحد يُفكّ مرة واحدة**، داخل `safeRequest`:

   ```json
   { "status": true, "message": "تم بنجاح", "data": { }, "meta": { } }
   ```

4. **`Dio` واحد من `GetIt`.** `Dio()` جديد داخل data source يفقد التوكن والمهل والتسجيل بصمت.
5. **معاملات فارغة تُحذف لا تُرسل null** — `null` في query string يصبح النص `"null"`.
6. **العقد الحي هو مواصفة OpenAPI**: شغّل الباك إند وافتح `http://localhost:8000/docs/api`. إن اختلف كودنا عنها، فالمواصفة على حق.

### البيئات

| الـ flavor | الملف | الأمر |
|---|---|---|
| `dev` | `.env.dev` | `flutter run --dart-define=FLAVOR=dev` |
| `prod` | `.env` | `flutter run` |

محاكي أندرويد يصل للمضيف عبر `10.0.2.2` لا `127.0.0.1` — [AppConfig](lib/core/config/app_config.dart) يختار تلقائياً.

---

## 7. الواجهة

- **`context.colorScheme` دائماً** ([context_extensions.dart](lib/core/utils/context_extensions.dart)). **لا `Color(0xff…)` ثابت** — الثيم يتغير والألوان المكتوبة يدوياً لا.
- **الثيم مولّد** من Material Theme Builder في [core/theme/](lib/core/theme/) — يُستبدل كاملاً عند تغيير اللوحة، ولذلك هو مستثنى من الـ linter ولا يُحرَّر يدوياً.
- **الأيقونات من [AppIcons](lib/core/utils/app_icons.dart) دائماً** — `Icons.*` أو `CupertinoIcons.*` مباشرة في شاشة ممنوع. أندرويد يأخذ مجموعة Material وiOS يأخذ Cupertino، والقرار في مكان واحد: أيقونة iOS في يد مستخدم أندرويد تُقرأ قبل أن تُفهم.
- **`.w` / `.h` / `.sp`** من ScreenUtil للأبعاد.
- **`withValues(alpha:)` لا `withOpacity()`** (Material 3).
- **`const` حيثما أمكن** — مفعّل كـ lint.
- **العربية RTL** هي اللغة الوحيدة؛ `Locale('ar')` مثبّت في [app.dart](lib/app.dart).
- **الرسائل للمستخدم بالعربية**، والكود والتعليقات بالإنجليزية.

### الويدجتات المشتركة

| الأداة | الاستخدام |
|---|---|
| [`AppButton`](lib/core/widgets/app_button.dart) | **كل زر في الشاشات.** `AppButton` للإجراء الرئيسي، `.tonal` للمساند، `.outlined` للخروج |
| [`AppTextField`](lib/core/widgets/app_text_field.dart) | كل حقل إدخال — و`.password` لكلمة المرور بزر الإظهار |
| `showCustomSnackBar` / `context.showSuccess` / `context.showError` / `context.showFailure` | الرسائل |
| `showCustomDialog` | تأكيد |
| `showDestructiveDialog` | تأكيد حذف — زر أحمر، ولا إغلاق بالنقر خارجاً |
| `Validators` | تحقق الحقول |

`showCustomSnackBar` يستخدم `Overlay` لا `ScaffoldMessenger`، ليظهر فوق الحوارات والأوراق السفلية — وواحد فقط على الشاشة في أي لحظة.

**`FilledButton` / `OutlinedButton` مباشرةً ممنوعان في الشاشات** — استعمل `AppButton`. الاستثناء الوحيد `showCustomDialog`: `AlertDialog.actions` يرتّب أزراره بنفسه.

**الانشغال يُمرَّر بـ `isLoading` لا بـ `onPressed: null`:**

```dart
AppButton(label: 'تسجيل الدخول', isLoading: state.isSubmitting, onPressed: _submit)
```

`onPressed: null` يعني «غير متاح» فيصير الزر رمادياً؛ الزر الذي يشحب في منتصف الطلب يبدو معطّلاً لا مشغولاً. `AppButton` يرفض النقر أثناء `isLoading` بنفسه.

### الحركة

- **الحركة داخل العنصر، ومقاسه لا يتغيّر.** لا `Transform.scale`، ولا عرض أو نصف قطر أو ظل متحرّك. كل قيمة متحركة يجب أن تكون **إزاحة أو شفافية** — وحدهما لا يستطيعان تغيير المقاس. العنصر الذي يكبر أو يصغر يجرّ ما حوله ويجبر العين على البحث عنه من جديد بعد كل لمسة.
- **الظل تحديداً ثابت.** الظل يُرسم *خارج* حدود الشكل، فتحريكه تحريكٌ خارج العنصر وتغيير في امتداده الظاهر.
- **الحركة صفة العنصر لا صفة الشاشة.** يجب أن تُقرأ صحيحة على «إلغاء» كما على «تسجيل الدخول». التصميم الذي يعمل لغرض واحد فقط ليس مكانه `core/widgets/`.
- **كل حركة تحترم `MediaQuery.disableAnimationsOf(context)`** — إعداد إمكانية وصول لا ذوق: الحركة تسبّب دواراً لبعض المستخدمين. **يُلغى المخرج نفسه لا المدّة فقط**: الحركة تكون *غائبة* لا *سريعة*، ولا يعمل أي `Ticker` في أي حالة.
- **في اختبارات الويدجت: لا `pumpAndSettle` مع أي رسم متحرك مكرّر** (`repeat()`، أو `CircularProgressIndicator`) — لا يستقرّ أبداً والاختبار ينتهي بانتهاء المهلة. استعمل `pump(duration)` صريحة.
- **`AnimationController` بحدّ أدنى سالب يبدأ عند الحدّ الأدنى** لا عند الصفر. اكتب `value: 0` صراحةً.

---

## 8. التحقق من المدخلات

`Validators` **خدمة لا ضمانة**: الخادم يتحقق مرة أخرى و 422 منه هو الجواب الحقيقي. التحقق هنا يوفّر رحلة شبكة ويضع الرسالة عند الحقل.

```dart
TextFormField(validator: Validators.libyanPhone)
TextFormField(validator: Validators.compose([Validators.required, Validators.minLength(3)]))
TextFormField(validator: Validators.optional(Validators.email))   // حقل اختياري
```

- **الأرقام العربية `٠١٢٣` مقبولة** — هذا ما تنتجه لوحة المفاتيح، ورفضها خطأ لا يستطيع المستخدم تشخيصه.
- **الفاصلة `,` علامة عشرية مقبولة.**
- **حقل اختياري = `Validators.optional(...)`**، لا نسخة ثانية من الدالة.

---

## 9. الجودة والتحقق

> **كل سلوك له اختبار. تغيّر السلوك ⇒ تغيّر اختباره في نفس التعديل.**

### ماذا يُختبر

- **Cubits** — تسلسل الحالات، عبر `bloc_test` و repository مزيّف بـ `mocktail`. لا Dio، لا شبكة.
- **Validators و الدوال النقية** — مباشرة.
- **UseCases** حين تحمل قاعدة عمل حقيقية.
- **Widgets** للشاشات ذات التفاعل المعقّد.

انظر [cities_cubit_test.dart](test/features/cities/cities_cubit_test.dart) — الفاصل بين الطبقات هو ما يجعل التزييف سطراً واحداً.

### التغطية الدنيا لأي Cubit

- ✅ المسار الناجح — تسلسل `loading → loaded`
- ✅ الفشل — أن الرسالة القادمة من الخادم هي التي تظهر، لا رسالة عامة
- ✅ الحدود — قائمة فارغة، آخر صفحة، فشل صفحة إضافية
- ✅ عدم فقدان البيانات المعروضة عند فشل جزئي

### فحص الشاشة على الجهاز

```bash
flutter run test_driver/app.dart --dart-define=FLAVOR=dev
```

[test_driver/app.dart](test_driver/app.dart) هو نفس التطبيق مع `enableFlutterDriverExtension()`،
فيمكن فتح القائمة الجانبية أو تعبئة نموذج وأخذ لقطة لما يراه المستخدم فعلاً. **خارج `lib/`
عمداً** حتى لا يصل هذا الامتداد إلى بناء إنتاج. لا يحتاجه `flutter test` ولا يستعمله.

### شرط الدمج

```bash
flutter analyze   # No issues found!
flutter test      # All tests passed!
```

كلاهما أخضر، وإلا لا يُدمج. الـ lints في [analysis_options.yaml](analysis_options.yaml) مرفوعة إلى `error` عمداً — التحذير الذي لا يكسر البناء لا يقرأه أحد.

---

## 10. الأمان

- **التوكن في `flutter_secure_storage`** (Keychain / Keystore) — **لا** في `SharedPreferences`، فهي ملف XML نصي على جهاز مكسور الحماية.
- **`.env` و `.env.dev` في `.gitignore`.** أي مفتاح جديد يُضاف إلى `.env.example`.
- **`PrettyDioLogger` في `dev` فقط ومع `!kReleaseMode`** — الأجسام تحوي بيانات عملاء والتوكن.
- **`debugPrint` لا `print`** — `print` يبقى في بناء الإنتاج (`avoid_print` مفعّل).
- **403 لا يسجّل الخروج.** إخراج مستخدم لأنه فتح شاشة لا يملك صلاحيتها خطأ يبدو كانهيار.

---

## 11. Git

- فروع للميزات، رسائل commit بالإنجليزية مع بادئة: `feat:` · `fix:` · `refactor:` · `chore:`.
- **الملفات المولّدة (`.freezed.dart` / `.g.dart`) تُرفع إلى git.** قرار مقصود: استنساخ جديد
  يعمل فوراً بلا `build_runner`، و CI لا يحتاج خطوة توليد. المراجع يتجاهلها، فهي مستثناة من
  الـ analyzer أصلاً.
- **`.env` و `.env.dev` لا تُرفع.** كل مفتاح جديد يُضاف إلى `.env.example`.
- 🎯 أضف CI (analyze + test) حتى لا يصبح `main` أحمر.

---

## 12. إضافة ميزة جديدة — الوصفة

خذ [features/cities/](lib/features/cities/) كقالب، بهذا الترتيب:

1. `models/` — النموذج بـ Freezed + `@JsonKey` لكل مفتاح يختلف اسمه عن الـ API.
2. `repositories/x_repository.dart` — العقد المجرد.
3. `repositories/x_repository_impl.dart` — نداءات Dio عبر `safeRequest`.
4. `usecases/` — فعل لكل عملية.
5. `presentation/viewmodel/` — الـ Cubit و State بـ Freezed.
6. `presentation/views/` — الشاشة مع `switch` شامل.
7. **سجّل الميزة** في [Injector](lib/core/di/injector.dart) بدالة `_registerX` واحدة.
8. **اكتب اختبار الـ Cubit** — زيّف العقد المجرد، لا الـ `Impl`.
9. `dart run build_runner build`، ثم `flutter analyze`، ثم `flutter test`.

---

*وثيقة حيّة. حين تثبت قاعدة هنا أنها خاطئة، غيّرها وسجّل السبب — قرارات مقصودة لا قوالب منسوخة.*
