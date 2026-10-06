plugins {
    alias(libs.plugins.android.library)
}

// Software audio decoders (AC3, E-AC3, DTS, TrueHD, FLAC, Opus ...) for Media3, built from FFmpeg.
// The Java and C++ here come from AndroidX Media3 (Apache 2.0). FFmpeg itself is built as LGPL.
// Run ffmpeg-decoder/build-ffmpeg.sh once to build FFmpeg; until then this module still compiles,
// it just reports "not available" and the app falls back to the server converting the sound.

android {
    namespace = "androidx.media3.decoder.ffmpeg"
    compileSdk = 35

    defaultConfig {
        minSdk = 26
        consumerProguardFiles("consumer-rules.pro")
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    // Only build the native part once FFmpeg has been built (see build-ffmpeg.sh).
    if (file("src/main/jni/ffmpeg/android-libs").exists()) {
        ndkVersion = "26.1.10909125"
        externalNativeBuild {
            cmake {
                path = file("src/main/jni/CMakeLists.txt")
                version = "3.22.1"
            }
        }
    }
}

dependencies {
    implementation(libs.media3.exoplayer)
    implementation(libs.media3.decoder)
    implementation(libs.androidx.annotation)
    compileOnly(libs.checker.qual)
}
