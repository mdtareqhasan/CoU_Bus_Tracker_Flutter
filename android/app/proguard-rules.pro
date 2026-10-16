# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in the Android SDK's proguard-android.txt.

# ============================================================
# Google ML Kit - Text Recognition (Latin)
# ------------------------------------------------------------
# The google_mlkit_text_recognition plugin references optional
# script recognizers (Chinese, Devanagari, Japanese, Korean) that
# are NOT bundled as dependencies. R8 fails the release build
# because these classes are missing. Suppress the warnings so the
# build succeeds. If you later need one of these scripts, add the
# corresponding ML Kit dependency and remove the matching -dontwarn.
# ============================================================
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder

# Keep annotations that R8 may strip but are needed by reflection.
-keepattributes *Annotation*
-keep class com.google.mlkit.** { *; }
