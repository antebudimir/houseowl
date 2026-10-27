import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.antebudimir.houseowl"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.antebudimir.houseowl"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        resourceConfigurations += listOf(
            "en", "ar", "be", "bg", "br", "ca", "ca_valencia", "cs", "da", "de", 
            "de_CH", "el", "es", "et", "eu", "fa", "fi", "fr", "he", "hi", "hr", 
            "hu", "id", "it", "ja", "kab", "kk", "ko", "lt", "nb", "nl", "pa", 
            "pl", "pt", "pt_BR", "ro", "ru", "sk", "sl", "sr", "sv", "ta", "te", 
            "tr", "uk", "vi", "zh", "zh_HANT"
        )
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            val storeFileProp = keystoreProperties["storeFile"] as String?
            storeFile = if (storeFileProp != null) file(storeFileProp) else null
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
    // Strip residual Firebase / Google Play Services metadata (.properties)
    // files pulled in transitively by ML Kit barcode scanning. Their code is
    // already removed by R8; the files are inert, but they make the APK look
    // Firebase-based to scanners and audit tools on this privacy-focused
    // fork.
    packaging {
        resources {
            excludes += setOf(
                "firebase-*.properties",
                "play-services-*.properties",
                "transport-*.properties",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
