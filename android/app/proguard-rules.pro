# Retrofit annotations and interfaces
-keepattributes Signature
-keepattributes *Annotation*

-keep interface retrofit2.** { *; }
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }



# sqflite
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**
