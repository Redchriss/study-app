import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") version "4.4.4"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "mw.yaza.studyapp"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "mw.yaza.studyapp"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // Load keystore properties from environment or local file
            val keystorePropertiesFile = rootProject.file("keystore.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(keystorePropertiesFile.inputStream())
                storeFile = file(keystoreProperties.getProperty("storeFile")!!)
                storePassword = keystoreProperties.getProperty("storePassword")!!
                keyAlias = keystoreProperties.getProperty("keyAlias")!!
                keyPassword = keystoreProperties.getProperty("keyPassword")!!
            } else {
                // Fallback to environment variables for CI/CD
                storeFile = file(System.getenv("KEYSTORE_FILE") ?: "debug.keystore")
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "android"
                keyAlias = System.getenv("KEY_ALIAS") ?: "androiddebugkey"
                keyPassword = System.getenv("KEY_PASSWORD") ?: "android"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
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

// Kotlin 2.x: replace deprecated android.kotlinOptions.jvmTarget
tasks.withType<KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}
