import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.royaldoor.live"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.royaldoor.live"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = Properties()
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(keystorePropertiesFile.inputStream())
            }
            
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                storeFile = if (File(storeFilePath).isAbsolute) {
                    file(storeFilePath)
                } else {
                    file("../$storeFilePath")
                }
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig?.storeFile?.exists() == true) {
                signingConfig = releaseSigningConfig
            }
            // If release keystore is missing locally, keep using debug signing for local development.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    bundle {
        language {
            // Ensure a single AAB is produced, not split-per-language, so Flutter tooling can locate it.
            enableSplit = false
        }
    }

    packaging {
        resources {
            pickFirst("lib/arm64-v8a/libaosl.so")
            pickFirst("lib/armeabi-v7a/libaosl.so")
            pickFirst("lib/x86/libaosl.so")
            pickFirst("lib/x86_64/libaosl.so")
            pickFirst("**/libc++_shared.so")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}

tasks.register("copyApkToFlutter") {
    doLast {
        copy {
            from("build/outputs/apk/debug")
            into("../../build/app/outputs/apk/debug")
            include("*.apk")
        }
        copy {
            from("build/outputs/apk/debug")
            into("../../build/app/outputs/flutter-apk")
            include("*.apk")
        }
    }
}

tasks.whenTaskAdded {
    if (name == "assembleDebug") {
        finalizedBy("copyApkToFlutter")
    }
}

tasks.register<Copy>("copyAabToFlutter") {
    dependsOn("bundleRelease")
    from("build/outputs/bundle/release")
    into("../../build/app/outputs/bundle/release")
    include("*.aab")
}

tasks.whenTaskAdded {
    if (name == "bundleRelease") {
        finalizedBy("copyAabToFlutter")
    }
}
