plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // Applied here, not left to the plugins that need it. `file_picker`, `share_plus` and
    // `flutter_plugin_android_lifecycle` are written in Kotlin, and on AGP 8 the Kotlin Gradle
    // Plugin is what compiles them. The version is declared once, in settings.gradle.kts.
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ly.dayaa.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ly.dayaa.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // نكهتان: ما يصل المتجر، وما يصل المُختبِر.
    //
    // **والغرضُ أن تتعايشا على الجهاز نفسه.** المُختبِرُ يحمل الاثنتين، فلو تشاركتا
    // `applicationId` لحلّت إحداهما محلّ الأخرى عند التنصيب — ولو تشابهتا في الأيقونة والاسم
    // لفتح الخطأَ وأبلغ عن عطلٍ في غير موضعه. فاللاحقةُ تفصل الحزمتين، و`src/dev/res` يحمل
    // اسماً وأيقونةً مختلفين.
    //
    // اسمُ النكهة `dev` لا `test`: `test` اسمٌ محجوزٌ لمجموعة مصادر اختبارات الوحدة في Gradle،
    // ونكهةٌ بذلك الاسم تصطدم بها. وهو الاسمُ نفسه الذي تقرأ به `AppConfig` ملفَّ البيئة
    // (`--dart-define=FLAVOR=dev` ← `.env.dev`)، فالسلسلةُ واحدة من سطر الأمر إلى العنوان.
    flavorDimensions += "env"

    productFlavors {
        create("prod") {
            dimension = "env"
        }

        create("dev") {
            dimension = "env"
            // ly.dayaa.app.dev — حزمةٌ أخرى، فتُنصَّب بجانب الإنتاج لا فوقه.
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-test"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
