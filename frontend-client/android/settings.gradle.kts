pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP, KGP and the Gradle wrapper follow what `flutter create` writes for the pinned Flutter
    // SDK. Flutter 3.50 refuses to build below AGP 9.1.1 and KGP 2.4.10, and its Gradle plugin
    // calls AGP 9 APIs, so `--android-skip-build-dependency-validation` is no way around it.
    //
    // **Built-in Kotlin stays off** (`android.builtInKotlin=false` in gradle.properties, as the
    // template has it). With it off, every plugin applies the Kotlin Gradle Plugin itself, and
    // so does `app`. `file_picker` 11 is the exception and gets KGP from the root
    // build.gradle.kts. Turning built-in Kotlin on is a separate job: every plugin in
    // pubspec.lock has to support it first.
    //
    // `frontend` carries the same versions; the two apps must not drift on this.
    id("com.android.application") version "9.3.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.4.4") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
}

include(":app")
