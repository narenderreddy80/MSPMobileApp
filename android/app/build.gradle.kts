import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read Google Maps API key from backend appsettings.json
fun getGoogleApiKey(): String {
    val appsettings = file("${rootProject.projectDir}/../../MSPRestAPI/FarmersRestApi/appsettings.json")
    if (appsettings.exists()) {
        val json = JsonSlurper().parse(appsettings) as Map<*, *>
        val maps = json["GoogleMaps"] as? Map<*, *>
        val key = maps?.get("ApiKey") as? String
        if (!key.isNullOrBlank() && !key.contains("YOUR_")) return key
    }
    return "MISSING_API_KEY"
}

android {
    namespace = "com.msp.msp_mobile_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.msp.msp_mobile_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Inject Google API key from backend appsettings.json into AndroidManifest
        manifestPlaceholders["GOOGLE_API_KEY"] = getGoogleApiKey()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
