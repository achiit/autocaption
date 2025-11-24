## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Keep generated files
-keep class androidx.lifecycle.** { *; }
-keep class com.google.android.gms.** { *; }

## Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

## Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## Video player
-keep class io.flutter.plugins.videoplayer.** { *; }

## Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

## Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

## Keep Pigeon generated code
-keep class dev.flutter.pigeon.** { *; }

## Keep all generated plugin registrants
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
