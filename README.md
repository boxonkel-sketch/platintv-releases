# platintv-releases

Veröffentlichte Versionen von PlatinTV.

## Enthaltene Fremdsoftware

Ab Version 0.7.0 enthält PlatinTV:

- **FFmpeg 6.0.1** unter der GNU Lesser General Public License 2.1 oder neuer ([LICENSE.FFmpeg.LGPLv2.1](LICENSE.FFmpeg.LGPLv2.1)). Gebaut sind nur Tondecoder: AAC, AAC LATM, AC-3, E-AC-3, DTS, MLP, TrueHD, MP2, MP3, Vorbis, Opus, FLAC und ALAC. Es sind keine GPL- oder Nonfree-Teile aktiviert.
- **AndroidX Media3 1.5.0** unter der Apache License 2.0 ([LICENSE.Media3.Apache-2.0](LICENSE.Media3.Apache-2.0)). Die Datei `FfmpegAudioDecoder.java` ist leicht geändert: Fehlende AAC- oder Opus-Startdaten führen nicht mehr zum Absturz.

FFmpeg ist statisch in `lib/<abi>/libffmpegJNI.so` der APK gelinkt. Die Quellen jeder Version liegen als Anhang am jeweiligen Release:

- `ffmpeg-n6.0.1-source.tar.xz`: FFmpeg, Tag `n6.0.1`, unverändert
- `media3-1.5.0-decoder_ffmpeg-source.tar.xz`: JNI-Schicht und Java-Teil von Media3, Tag `1.5.0`
- `build_ffmpeg.sh`: genau so wurde `libffmpegJNI.so` gebaut (Konfiguration, NDK r26, API 24, armeabi-v7a und arm64-v8a)

## FFmpeg austauschen

Die App spricht FFmpeg nur über die JNI-Schnittstelle von Media3 an. So baust du eine eigene Version ein:

1. Beide Quellpakete entpacken, FFmpeg nach Wunsch ändern.
2. `build_ffmpeg.sh` anpassen und ausführen, das ergibt neue `libffmpegJNI.so`.
3. In der APK `lib/armeabi-v7a/libffmpegJNI.so` und `lib/arm64-v8a/libffmpegJNI.so` ersetzen, die APK mit `zipalign` ausrichten und mit eigenem Schlüssel signieren (`apksigner`).

Eine so neu signierte APK lässt sich nicht über eine bestehende Installation spielen, sondern nur neu installieren.
