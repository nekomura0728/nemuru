import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.nemuruapp.nemuru"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nemuruapp.nemuru"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists() && 
            keystoreProperties.getProperty("keyAlias") != null &&
            keystoreProperties.getProperty("keyPassword") != null &&
            keystoreProperties.getProperty("storeFile") != null &&
            keystoreProperties.getProperty("storePassword") != null) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword") 
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Only apply signing config if it was created
            if (keystorePropertiesFile.exists() && 
                keystoreProperties.getProperty("keyAlias") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Force Google Play Billing Library 7.0.0 for Google Play Console requirement
configurations.configureEach {
    resolutionStrategy {
        force("com.android.billingclient:billing:7.0.0")
        // Force all billing related dependencies to use v7.0.0
        force("com.android.billingclient:billing-ktx:7.0.0")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Force Google Play Billing Library 7.0.0 for Google Play Console requirement
    implementation("com.android.billingclient:billing:7.0.0")
    implementation("com.android.billingclient:billing-ktx:7.0.0")
    // AndroidX Core for edge-to-edge support
    implementation("androidx.core:core:1.12.0")
    implementation("androidx.core:core-ktx:1.12.0")
}

flutter {
    source = "../.."
}
