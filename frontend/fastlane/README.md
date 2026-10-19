fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios submit

```sh
[bundle exec] fastlane ios submit
```

رفع IPA + إنشاء النسخة وإرسالها للمراجعة

### ios upload_build

```sh
[bundle exec] fastlane ios upload_build
```

رفع IPA كـ Build فقط (TestFlight) بلا إنشاء نسخة ولا إرسال للمراجعة

### ios check_test_version

```sh
[bundle exec] fastlane ios check_test_version
```

فحص مبكر لنسخة تجريبية: هل مسار (train) هذه النسخة ما زال مفتوحاً في TestFlight؟

### ios check_version

```sh
[bundle exec] fastlane ios check_version
```

فحص مبكر: هل يمكن أصلاً إنشاء/تعديل هذه النسخة الآن؟

### ios cancel_pending_review

```sh
[bundle exec] fastlane ios cancel_pending_review
```

سحب النسخة الحالية من المراجعة وانتظار عودتها قابلة للتعديل

### ios status

```sh
[bundle exec] fastlane ios status
```

طباعة حالة آخر النسخ في App Store Connect (للتشخيص)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
