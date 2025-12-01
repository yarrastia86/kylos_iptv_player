# Kylos IPTV Player - ProGuard/R8 Rules
#
# These rules configure R8 (the default code shrinker) for release builds.
# R8 is backwards compatible with ProGuard rules.
#
# Key objectives:
# 1. Obfuscate code to raise the bar for reverse engineering
# 2. Shrink unused code to reduce APK size
# 3. Preserve necessary classes for reflection-based frameworks
#
# SECURITY NOTE: Obfuscation is NOT encryption. A determined attacker
# can still reverse engineer the app. This is defense-in-depth.

#------------------------------------------------------------------------------
# General R8/ProGuard Settings
#------------------------------------------------------------------------------

# Preserve line numbers and source file names for crash reports
# This makes debugging production issues possible while still obfuscating
-keepattributes SourceFile,LineNumberTable

# If you use line numbers, hide the original source file name
-renamesourcefileattribute SourceFile

# Preserve annotation information for runtime reflection
-keepattributes *Annotation*

# Preserve generic type information (needed by Gson, etc.)
-keepattributes Signature

# Preserve exception information
-keepattributes Exceptions

#------------------------------------------------------------------------------
# Flutter Framework
#------------------------------------------------------------------------------

# Flutter engine classes must not be obfuscated
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dart native interface
-keep class io.flutter.embedding.** { *; }

#------------------------------------------------------------------------------
# Firebase
#------------------------------------------------------------------------------

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keepattributes *Annotation*

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }

# Firebase Remote Config
-keep class com.google.firebase.remoteconfig.** { *; }

# Firebase Crashlytics (when added)
-keep class com.google.firebase.crashlytics.** { *; }
-keepattributes SourceFile,LineNumberTable

# Firebase App Check (when added)
-keep class com.google.firebase.appcheck.** { *; }

#------------------------------------------------------------------------------
# Google Play Services
#------------------------------------------------------------------------------

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# In-App Billing
-keep class com.android.vending.billing.** { *; }

#------------------------------------------------------------------------------
# Media Playback (media_kit / libmpv)
#------------------------------------------------------------------------------

# media_kit native library interface
-keep class com.alexmercerind.media_kit.** { *; }
-keep class com.alexmercerind.media_kit_video.** { *; }

# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

#------------------------------------------------------------------------------
# Secure Storage (flutter_secure_storage)
#------------------------------------------------------------------------------

# flutter_secure_storage uses reflection for keystore access
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Android Keystore classes
-keep class android.security.** { *; }
-keep class javax.crypto.** { *; }

#------------------------------------------------------------------------------
# Networking (Dio)
#------------------------------------------------------------------------------

# Dio HTTP client
-keep class io.flutter.plugins.** { *; }

# OkHttp (used by many plugins)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

#------------------------------------------------------------------------------
# JSON Serialization (json_serializable)
#------------------------------------------------------------------------------

# Keep generated JSON serialization classes
# These are typically named *_$fromJson and *_$toJson
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Freezed generated classes
-keep class **_$*.** { *; }

#------------------------------------------------------------------------------
# Kotlin
#------------------------------------------------------------------------------

-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

#------------------------------------------------------------------------------
# Application-Specific Rules
#------------------------------------------------------------------------------

# Keep data classes that are serialized to/from JSON
# Add specific keep rules for your data models if needed
# Example:
# -keep class com.kylos.iptvplayer.models.** { *; }

# Keep classes accessed via reflection in plugins
# Add rules here if you encounter ClassNotFoundException in release builds

#------------------------------------------------------------------------------
# Debugging Removed Code (use only for troubleshooting)
#------------------------------------------------------------------------------

# Uncomment to see what R8 removes (generates large output)
# -printusage usage.txt

# Uncomment to see the mapping of obfuscated names
# -printmapping mapping.txt

# Uncomment to see the merged configuration
# -printconfiguration full-r8-config.txt

#------------------------------------------------------------------------------
# Aggressive Optimization (optional, may cause issues)
#------------------------------------------------------------------------------

# Uncomment for more aggressive optimization (test thoroughly!)
# -optimizationpasses 5
# -allowaccessmodification
# -repackageclasses ''
