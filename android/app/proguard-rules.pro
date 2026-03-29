# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in C:\Users\Nitro\develop\flutter/packages/flutter_tools/gradle/flutter_proguard_rules.pro
# Learn more at: https://developer.android.com/guide/navigation/navigation-principles#proguard

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings
