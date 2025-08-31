plugins {
    id("com.android.application")
    id("kotlin-android")
    // Il plugin Flutter va applicato dopo Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nome_tuo_progetto" // <-- cambia col tuo package
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.nome_tuo_progetto" // <-- uguale al package definitivo
        // Minimo 21 come richiesto
        minSdk = 21
        // compile/target presi dal plugin Flutter (>= 33 va bene)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Java/Kotlin 17 è lo standard dei template Flutter recenti
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildTypes {
        release {
            // Firma di debug per comodità; sostituisci con la tua keystore per la pubblicazione
            signingConfig = signingConfigs.getByName("debug")
            // Per abilitare minify/shrink:
            // isMinifyEnabled = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}
