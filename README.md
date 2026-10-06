# ffmpeg-decoder

Software audio decoding for the Bearfin player, so sound formats most phones can't decode
(AC3, E-AC3, DTS, TrueHD, and more) play straight from the file instead of the server converting them.

## Build it once

```
./ffmpeg-decoder/build-ffmpeg.sh
./gradlew assembleDebug
```

Until FFmpeg is built, the module still compiles and the app simply falls back to the server
converting the sound.

## Licenses

- `src/main/java` and `src/main/jni/ffmpeg_jni.cc` / `CMakeLists.txt`: AndroidX Media3 FFmpeg
  extension, Apache License 2.0, Copyright (C) The Android Open Source Project
  (see `LICENSE-media3-APACHE-2.0`). Unmodified copies from Media3 1.5.0.
- FFmpeg 6.0 (downloaded by the script, not stored in this repository): LGPL 2.1 or later.
  `build-ffmpeg.sh` does **not** pass `--enable-gpl` or `--enable-nonfree`. FFmpeg is linked
  statically into `libffmpegJNI.so`. The complete source of Bearfin and the exact build script are
  published so the library can be rebuilt with a modified FFmpeg, as the LGPL requires.
  FFmpeg is a trademark of Fabrice Bellard. See https://ffmpeg.org/legal.html
