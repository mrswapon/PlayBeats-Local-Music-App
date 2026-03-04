# PlayBeats

A beautifully crafted local music player for Android, built with Flutter. PlayBeats scans your device for audio files and plays them with a stunning neumorphic UI, turntable-style player, and smooth animations.

## Features

- **Local Music Playback** — Scans and plays audio files stored on your device
- **Turntable Player** — Full-screen player with spinning vinyl, tonearm, and equalizer visualization
- **Neumorphic UI** — Raised/pressed card design with dual-shadow depth across the entire app
- **Dark & Light Mode** — Toggle between dark and light themes, persisted across sessions
- **Browse by Artist & Album** — Organized browsing with embedded album artwork
- **Favorites** — Save and manage your favorite tracks
- **Search** — Quickly find songs and artists from your library
- **Background Playback** — Continues playing with notification controls and lock screen media support
- **Shuffle & Auto-Advance** — Shuffle mode and automatic next-song playback
- **Seekable Progress Bar** — Drag to seek through the current track
- **Custom Painted Icons** — Hand-drawn nav bar icons (home, planet, bookmark)
- **Onboarding** — Animated welcome screen with custom-painted vinyl, CD, and cassette illustrations
- **Staggered Animations** — Smooth entry animations on the songs list

## Screenshots 

_Add screenshots here_

## Architecture

PlayBeats follows **clean architecture** with a **feature-based folder structure** and **BLoC pattern** for state management.

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   └── theme/
│       ├── app_theme.dart          # AppColors ThemeExtension + light/dark themes
│       ├── neumorphic.dart         # Neu.raised / pressed / circular helpers
│       └── theme_cubit.dart        # ThemeCubit with Hive persistence
├── data/
│   ├── models/
│   │   └── song_model.dart
│   ├── repositories/
│   │   ├── local_music_repository.dart
│   │   └── favorites_repository.dart
│   └── services/
│       ├── audio_player_service.dart
│       ├── hive_service.dart
│       └── local_music_service.dart
└── features/
    ├── browse/                     # Browse by artist / album
    ├── common/widgets/             # SongTile, ArtworkWidget
    ├── favorites/                  # Favorites list
    ├── onboarding/                 # Welcome screen
    ├── player/                     # Turntable player + mini player
    ├── shell/                      # AppShell with floating nav bar
    └── songs/                      # Songs list with explore layout
```

## Tech Stack

| Category | Library |
|----------|---------|
| Framework | Flutter 3.9+ |
| State Management | flutter_bloc |
| Audio Playback | just_audio, audio_service, audio_session |
| Music Scanning | on_audio_query |
| Permissions | permission_handler |
| Local Storage | hive, hive_flutter |
| UI | shimmer, custom painters |

## Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Android device or emulator (minSdk 21)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/play_beats.git
   cd play_beats
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Permissions

PlayBeats requires the following permissions on Android:

| Permission | Purpose |
|------------|---------|
| `READ_MEDIA_AUDIO` | Access audio files (Android 13+) |
| `READ_EXTERNAL_STORAGE` | Access audio files (Android 12 and below) |
| `FOREGROUND_SERVICE` | Background music playback |
| `WAKE_LOCK` | Keep playback alive while screen is off |

Permissions are requested at runtime when the app first loads.

## License

This project is licensed under the MIT License.
