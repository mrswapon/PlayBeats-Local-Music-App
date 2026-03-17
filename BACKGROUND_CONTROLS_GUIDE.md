# Background Media Controls - Implementation Guide

## ✅ Implemented Features

### Lock Screen & Notification Controls:
1. **Play/Pause Button** - Toggles playback state
2. **Next Button** - Skips to next track/video
3. **Previous Button** - Skips to previous track/video
4. **Seek Bar** - Drag to seek within track
5. **Album Art** - Shows video thumbnail or album art
6. **Track Info** - Title and artist display

### Background Playback:
- ✅ Audio continues when app is minimized
- ✅ Audio continues when screen is off
- ✅ Controls work from lock screen
- ✅ Controls work from notification shade
- ✅ Bluetooth headset controls supported
- ✅ Android Auto / CarPlay compatible

## How It Works

### Audio Service Configuration:
```dart
AudioService.init(
  builder: () => AudioPlayerService(),
  config: AudioServiceConfig(
    androidNotificationChannelId: 'com.mr_swapon.play_beats.audio',
    androidNotificationChannelName: 'PlayBeats Audio',
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidShowNotificationBadge: true,
    // ... other config
  ),
)
```

### Media Controls Setup:
```dart
playbackState.add(playbackState.value.copyWith(
  controls: [
    MediaControl.skipToPrevious,
    isPlaying ? MediaControl.pause : MediaControl.play,
    MediaControl.skipToNext,
  ],
  androidCompactActionIndices: [0, 1, 2], // Show all 3 in notification
));
```

### Event Handlers:
- `play()` - Resume playback
- `pause()` - Pause playback
- `skipToNext()` - Play next item in playlist
- `skipToPrevious()` - Play previous item
- `seek(position)` - Seek to position
- `stop()` - Stop playback

## Testing

### From Lock Screen:
1. Play any video as audio
2. Lock your phone
3. You'll see media controls on lock screen
4. Tap Play/Pause/Next/Previous - all should work

### From Notification Shade:
1. Play any video as audio
2. Pull down notification shade
3. Media notification shows with controls
4. All controls work without unlocking

### With Screen Off:
1. Play video as audio
2. Turn off screen
3. Press headphone button (if supported)
4. Controls should respond

### Bluetooth/Car:
1. Connect Bluetooth headset or Car
2. Play video as audio
3. Use headset/car controls
4. Playback responds to button presses

## Troubleshooting

### Controls Not Working?

**Check Permissions:**
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

**Check Service Declaration:**
```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>

<receiver
    android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</receiver>
```

### Notification Not Showing?

1. Check notification channel is created
2. Ensure `androidNotificationIcon` is set
3. Verify notification permissions granted
4. Check Do Not Disturb mode is off

### App Crashes When Using Controls?

Check Logcat for errors:
```bash
adb logcat | grep -i "audio"
adb logcat | grep -i "mediasession"
```

## Supported Platforms

| Platform | Lock Screen | Notification | Bluetooth | Android Auto |
|----------|-------------|--------------|-----------|--------------|
| Android 10+ | ✅ | ✅ | ✅ | ✅ |
| Android 11+ | ✅ | ✅ | ✅ | ✅ |
| Android 12+ | ✅ | ✅ | ✅ | ✅ |
| Android 13+ | ✅ | ✅ | ✅ | ✅ |

## Known Limitations

1. **Album Art**: May not show on all devices (depends on ROM)
2. **Custom Icons**: Limited to system-provided icons
3. **Additional Buttons**: Only 3 compact actions shown in notification

## Build Commands

```bash
# Build release with background controls
flutter build apk --release

# Install and test
flutter install --release

# Or manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Files Modified

1. `lib/data/services/audio_player_service.dart` - Core service
2. `android/app/src/main/AndroidManifest.xml` - Permissions & services
3. `android/app/proguard-rules.pro` - Keep rules for release builds
