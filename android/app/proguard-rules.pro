# Flutter Engine rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# flutter_local_notifications keep rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# onenm_local_llm / llama.cpp keep rules
-keep class com.theorangeshade.onenm_local_llm.** { *; }
-keep class com.write4me.llama_flutter_android.** { *; }
-keep class com.onenm.local_llm.** { *; }
-keepclassmembers class * {
    native <methods>;
}
-keepclasseswithmembernames class * {
    native <methods>;
}

# Ignore missing Play Core classes (we don't use deferred components)
-dontwarn com.google.android.play.core.**
