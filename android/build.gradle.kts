// Root Android build script for Flutter (Kotlin DSL)

// Repositories for all modules
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Flutter's custom build directory logic
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

// Update build directories for all subprojects
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Ensure app module is evaluated first
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

/* ---------------------------------------------------
   FIX FOR PLUGINS MISSING compileSdk (e.g. speech_to_text)
   This is AGP 8–safe and fully Kotlin DSL.
   --------------------------------------------------- */
subprojects {

    // For Android library plugins (most Flutter plugins)
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(34)
            defaultConfig.targetSdk = 34
        }
    }

    // For Android application modules (rarely needed here)
    plugins.withId("com.android.application") {
        extensions.configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(34)
            defaultConfig.targetSdk = 34
        }
    }
}
