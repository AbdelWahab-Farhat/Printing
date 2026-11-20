allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// `file_picker` 11 applies the Kotlin Gradle Plugin only below AGP 9, assuming built-in Kotlin
// takes over at 9. It is off here (gradle.properties), so without this its Kotlin sources are
// never compiled and the build dies on «cannot find symbol: class FilePickerPlugin» in the
// generated registrant. Its 13 line honours the switch, but needs win32 6, which drags in
// share_plus 13, package_info_plus and flutter_secure_storage 10. Drop this once that upgrade
// lands.
subprojects {
    if (name == "file_picker") {
        pluginManager.withPlugin("com.android.library") {
            pluginManager.apply("org.jetbrains.kotlin.android")
            extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
