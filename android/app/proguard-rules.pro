# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Core (for Flutter)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# PayHere - ALL classes
-keep class lk.payhere.** { *; }
-keep interface lk.payhere.** { *; }
-keep class * extends lk.payhere.** { *; }
-dontwarn lk.payhere.**

# Conscrypt (SSL library)
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Retrofit
-keepattributes Signature, *Annotation*
-keep class retrofit2.** { *; }
-keep interface retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# Gson
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# Generic
-keepattributes SourceFile,LineNumberTable
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Sqflite
-keep class com.tekartik.sqflite.** { *; }
-keepnames class com.tekartik.sqflite.** { *; }

# Sqflite Required (missing)
-keep class androidx.sqlite.db.** { *; }
-keep class android.database.** { *; }

# Native SQLite
-keep class org.sqlite.** { *; }

# Flutter Engine Plugins (required in new Flutter versions)
-keep class io.flutter.embedding.engine.plugins.** { *; }
