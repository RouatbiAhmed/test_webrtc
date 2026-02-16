buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

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

// <<< THIS IS THE IMPORTANT PART >>>
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            extensions.findByName("android")?.let { androidExt ->
                val android = androidExt as com.android.build.gradle.BaseExtension
                android.lintOptions {
                    // Ignore plugin lint errors
                    isAbortOnError = false
                    disable.addAll(listOf("NewApi", "MissingTranslation", "UnusedResources", "ProtectedPermissions"))
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
