import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.royaldoor.live"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    lint {
        checkReleaseBuilds = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.royaldoor.live"
        minSdk = 25
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
        jniLibs {
            pickFirsts.add("lib/arm64-v8a/libaosl.so")
            pickFirsts.add("lib/armeabi-v7a/libaosl.so")
            pickFirsts.add("lib/x86/libaosl.so")
            pickFirsts.add("lib/x86_64/libaosl.so")
            pickFirsts.add("**/libc++_shared.so")
        }
        resources {
            excludes.add("/META-INF/{AL2.0,LGPL2.1}")
            excludes.add("META-INF/DEPENDENCIES")
            excludes.add("META-INF/LICENSE")
            excludes.add("META-INF/LICENSE.txt")
            excludes.add("META-INF/license.txt")
            excludes.add("META-INF/NOTICE")
            excludes.add("META-INF/NOTICE.txt")
            excludes.add("META-INF/notice.txt")
            excludes.add("META-INF/ASL2.0")
            excludes.add("META-INF/*.kotlin_module")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.firebase:firebase-appcheck-playintegrity:19.2.0")
    debugImplementation("com.google.firebase:firebase-appcheck-debug:19.2.0")
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
