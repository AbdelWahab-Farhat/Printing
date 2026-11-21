import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // Applied here, not left to the plugins that need it. `file_picker` and
    // `flutter_plugin_android_lifecycle` are written in Kotlin, and with built-in Kotlin off
    // (gradle.properties) the Kotlin Gradle Plugin is what compiles them — as is our own
    // MainActivity.kt. The version is declared once, in settings.gradle.kts.
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The Play upload key lives outside the repo. `android/key.properties` (git-ignored) points
// at it with storeFile, storePassword, keyAlias and keyPassword. Without that file, release
// builds fall back to the debug key so `flutter run --release` still works on any machine,
// but Play Console rejects a bundle signed that way.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasUploadKey = keystorePropertiesFile.exists()

android {
    namespace = "ly.dayaa.client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ly.dayaa.client"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // نكهتان: ما يصل المتجر، وما يصل المُختبِر — كما في تطبيق الموظفين منذ ٢١ سبتمبر.
    //
    // **والغرضُ أن تتعايشا على الجهاز نفسه.** المُختبِرُ يحمل الاثنتين، فلو تشاركتا
    // `applicationId` لحلّت إحداهما محلّ الأخرى عند التنصيب — ولو تشابهتا في الأيقونة والاسم
    // لفتح الخطأَ وأبلغ عن عطلٍ في غير موضعه. فاللاحقةُ تفصل الحزمتين، و`src/dev/res` يحمل
    // اسماً وأيقونةً مختلفين.
    //
    // اسمُ النكهة `dev` لا `test`: `test` اسمٌ محجوزٌ لمجموعة مصادر اختبارات الوحدة في Gradle.
    // وهو الاسمُ نفسه الذي يختار به `AppConfig` ملفَّ البيئة (`--flavor dev` ← `.env.dev`)،
    // و`default-flavor: prod` في pubspec يُبقي `flutter run` بلا `--flavor` على الإنتاج.
    flavorDimensions += "env"

    productFlavors {
        create("prod") {
            dimension = "env"
        }

        create("dev") {
            dimension = "env"
            // ly.dayaa.client.dev — حزمةٌ أخرى، فتُنصَّب بجانب الإنتاج لا فوقه.
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-test"
        }
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (!hasUploadKey) {
                logger.warn("android/key.properties not found: signing release with the debug key.")
            }
            signingConfig = signingConfigs.getByName(if (hasUploadKey) "upload" else "debug")
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
