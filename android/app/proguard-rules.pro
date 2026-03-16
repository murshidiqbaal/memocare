# Google ML Kit ProGuard Rules

# General ML Kit rules
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }

# Text Recognition language-specific options (specifically requested)
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.latin.** { *; }

# Keep specific recognizer options and their internal classes
-keep class com.google.mlkit.vision.text.TextRecognizerOptionsInterface { *; }
-keep class com.google.android.gms.vision.text.** { *; }

# Common GMS / ML Kit dependencies
-keep class com.google.android.gms.common.internal.safeparcel.SafeParcelable { *; }
-keepnames class * implements com.google.android.gms.common.internal.safeparcel.SafeParcelable

# For Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Speech to Text rules (project uses speech_to_text)
-keep class dev.nfet.speech_to_text.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Record plugin
-keep class com.llfbandit.record.** { *; }
