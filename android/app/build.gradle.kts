plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")  // ← FIXED: Moved to new line
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.test_webrtc"
    compileSdk = flutter.compileSdkVersion.toInt()  // ← ADD .toInt()
    // ndkVersion = flutter.ndkVersion  // ← COMMENT THIS OUT or remove

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // This buildFeatures block is required by cloud_firestore
    buildFeatures {
        buildConfig = true
    }

    kotlinOptions {
        jvmTarget = "1.8"

    }

    defaultConfig {
        applicationId = "com.example.test_webrtc"
        minSdk = flutter.minSdkVersion.toInt()  // ← ADD .toInt()
        targetSdk = flutter.targetSdkVersion.toInt()  // ← ADD .toInt()
        versionCode = flutter.versionCode.toInt()  // ← ADD .toInt()
        versionName = flutter.versionName
        // Required by some Firebase libraries
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))

    // Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")

    // Add any other Firebase products you need, for example:
    implementation("com.google.firebase:firebase-firestore")  // ← UNCOMMENT THIS
}