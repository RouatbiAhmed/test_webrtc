plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.test_webrtc"
    compileSdk = flutter.compileSdkVersion.toInt()

    defaultConfig {
        applicationId = "com.example.test_webrtc"
        minSdk = 24  // ← fixed for flutter_callkit_incoming
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
        baseline = file("lint-baseline.xml")
        abortOnError = false
        disable.addAll(
            listOf(
                "ProtectedPermissions",
                "NewApi",
                "MissingTranslation",
                "UnusedResources"
            )
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")
}
