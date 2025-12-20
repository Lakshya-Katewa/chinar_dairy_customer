import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties().apply {
    val propertiesFile = rootProject.file("app/key.properties")
    if (propertiesFile.exists()) {
        load(FileInputStream(propertiesFile))
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.devtools.ksp") version "1.9.22-1.0.17"
}

android {
    namespace = "com.chinardairy.app"
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = "27.0.12077973"
    buildFeatures {
        buildConfig = true
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        
        // 1. ADD THIS LINE TO ENABLE DESUGARING
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.chinardairy.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        multiDexEnabled = true
        
        // Corrected resource value declaration
        resValue("string", "firebase_web_client_id", "AIzaSyC2jP3jMdHGjeSm4E0L9M62Zp5DpK6TvWg")
        
        manifestPlaceholders += mapOf(
            "firebaseAppCheckDebug" to "debug",
            "firebaseAppCheck" to "playIntegrity"
        )
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "null")
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
        }
    }
    
    buildTypes {
        getByName("debug") {
            manifestPlaceholders += mapOf("firebaseAppCheck" to "debug")
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // 2. UPDATED DEPENDENCY FOR DESUGARING AS PER ERROR LOG
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation("com.google.android.play:integrity:1.4.0")
    implementation("com.google.android.gms:play-services-safetynet:18.0.1")
    implementation("com.google.firebase:firebase-appcheck-playintegrity:17.1.2")
    implementation("com.google.firebase:firebase-appcheck-ktx:17.1.2")
    implementation("com.google.firebase:firebase-common-ktx:21.0.0")
    implementation("com.google.firebase:firebase-appcheck-debug:17.1.2")
    
    // ... other dependencies
}

flutter {
    source = "../.."
}

