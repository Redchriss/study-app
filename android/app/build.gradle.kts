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
            // CI and devs without an upload key: use debug keystore so `assembleRelease` works.
            // Tag/release workflows decode `release-keystore.jks` and write `keystore.properties`; then we override.
            initWith(signingConfigs.getByName("debug"))
            val keystorePropertiesFile = rootProject.file("keystore.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
                val storeRel = keystoreProperties.getProperty("storeFile")
                if (storeRel != null) {
                    val resolved = listOf(rootProject.file(storeRel), project.file(storeRel))
                        .firstOrNull { it.isFile }
                    if (resolved != null) {
                        storeFile = resolved
                        storePassword = keystoreProperties.getProperty("storePassword")!!
                        keyAlias = keystoreProperties.getProperty("keyAlias")!!
                        keyPassword = keystoreProperties.getProperty("keyPassword")!!
                    }
                }
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
    // Flutter embedding references Play Core for deferred components; R8 needs these
    // classes on the classpath when minifyReleaseWithR8 runs (see missing_rules / CI).
    implementation("com.google.android.play:core:1.10.3")
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
