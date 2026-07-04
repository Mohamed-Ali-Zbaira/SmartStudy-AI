# Garder les classes ML Kit
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Garder speech_to_text
        -keep class com.csdcorp.speech_to_text.** { *; }

# Garder les annotations
-keepattributes *Annotation*
        -keepattributes Signature

# Éviter les warnings
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.csdcorp.speech_to_text.**
-dontwarn org.jetbrains.kotlin.**