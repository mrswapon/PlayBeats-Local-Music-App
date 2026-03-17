## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Flutter Play Store Split
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.splitcompat.**

## Audio Service
-keep class com.ryanheise.audioservice.** { *; }
-keep class * extends com.ryanheise.audioservice.AudioService { *; }

## Just Audio
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

## Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

## Video Player
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

## Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

## Device Info Plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

## Video Thumbnail
-keep class **.*VideoThumbnail* { *; }

## Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlinx.coroutines.** { *; }
-keep class * implements kotlin.Metadata { *; }

## Gson
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Models
-keep class com.mr_swapon.play_beats.data.models.** { *; }
-keepclassmembers class com.mr_swapon.play_beats.data.models.** { *; }
