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
    // **Pinned to the 8 line on purpose — do not "upgrade" this to 9 without reading on.**
    //
    // AGP 9 compiles Kotlin itself and refuses any module that applies the Kotlin Gradle Plugin,
    // and our plugins are split down the middle on that: `file_picker` reads the AGP version and
    // *skips* KGP at 9+ (assuming built-in Kotlin is on), while `share_plus` and
    // `flutter_plugin_android_lifecycle` apply KGP unconditionally. Neither value of
    // `android.builtInKotlin` satisfies both — one half fails to compile, or the other half is
    // never compiled at all and the build dies at `compileReleaseJavaWithJavac` with
    // «cannot find symbol: class FilePickerPlugin» in the generated registrant.
    //
    // Flutter itself agrees: its DependencyVersionChecker warns above 8.11.1.
    // The way back to 9 is a release of all three plugins that supports built-in Kotlin, and
    // then `android.builtInKotlin=true` in gradle.properties — not this line alone.
    id("com.android.application") version "8.13.0" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
