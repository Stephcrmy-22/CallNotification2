plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.agora_voice_call"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.agora_voice_call"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // --- Fix duplicate libaosl.so issue for Agora ---
    packagingOptions {
        pickFirsts += listOf(
            "lib/x86/libaosl.so",
            "lib/x86_64/libaosl.so",
            "lib/armeabi-v7a/libaosl.so",
            "lib/arm64-v8a/libaosl.so"
        )
    }
}

dependencies {
    // --- Firebase ---
    implementation(platform("com.google.firebase:firebase-bom:34.10.0"))
    implementation("com.google.firebase:firebase-analytics")

    // --- Agora infra library (prevents libaosl.so conflicts) ---
    implementation("io.agora.infra:aosl:1.2.13")

    // --- Optional: other dependencies if needed ---
    // implementation("io.agora.rtm:agora-rtm:2.2.1") // if using RTM v2.2.1 via Maven
}

flutter {
    source = "../.."
}