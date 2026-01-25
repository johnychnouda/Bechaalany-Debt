import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties from key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bechaalany.debt.bechaalanyDebtApp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bechaalany.debt.bechaalanyDebtApp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFile = keystoreProperties["storeFile"]?.toString()?.let { file(it) }
            if (keystorePropertiesFile.exists() && storeFile != null && storeFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"]?.toString() ?: ""
                keyPassword = keystoreProperties["keyPassword"]?.toString() ?: ""
                this.storeFile = storeFile
                storePassword = keystoreProperties["storePassword"]?.toString() ?: ""
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if keystore properties are available and keystore file exists
            // Otherwise fall back to debug (for development only)
            val storeFile = keystoreProperties["storeFile"]?.toString()?.let { file(it) }
            if (keystorePropertiesFile.exists() && storeFile != null && storeFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
                println("WARNING: Using debug signing. Keystore file not found. Create android/key.properties and keystore file for release signing.")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
