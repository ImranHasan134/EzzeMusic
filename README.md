# EzzeMusic 🎵

A beautifully designed, feature-rich local music player built with Flutter. EzzeMusic offers a premium dark luxury listening experience with smooth animations, responsive layouts, and robust playback controls.

---

## Features

### 🎵 Playback
- Play local audio files from device storage
- Background playback with lock screen
- Play/Pause, Next, Previous controls
- Seek bar with real-time position tracking
- Shuffle mode
- Repeat modes — Off, Repeat All, Repeat One
- Sleep timer (15 min, 30 min, 1 hour)
- Restores last played queue on app restart

### 📋 Library
- Scan device for all audio files
- Import songs from Files app
- Songs list with A–Z / Z–A sorting

### 🎶 Playlists
- Create, rename, and delete playlists
- Add / remove songs from playlists
- Dedicated playlist detail screen

### ❤️ Favourites
- Add currently playing song to Favourites
- Remove song from Favourites with one tap
- Favourites stored as a dedicated playlist

### 🎨 Design
- Dark luxury theme with warm orange accent (`#FF6B35`)
- Smooth press-scale animations on all interactive elements
- Pulsing artwork glow animation on Now Playing screen
- Themed custom bottom navigation bar
- Mini player bar with live progress indicator
- Fully responsive — adapts to all screen sizes
- Consistent design language across all screens

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| Audio Playback | `just_audio` |
| Background Audio | `just_audio_background` |
| State Management | `provider` |
| Persistence | `shared_preferences` |
| File Picking | `file_picker` |
| Utilities | `collection` |

---

## Project Structure
```
lib/
├── main.dart
└── src/
    ├── data/
    │   └── songs_repository.dart
    ├── models/
    │   ├── playlist.dart
    │   └── song.dart
    ├── state/
    │   ├── app_state.dart
    │   └── player_controller.dart
    └── ui/
        ├── screens/
        │   ├── home_screen.dart
        │   ├── now_playing_screen.dart
        │   ├── playlist_detail_screen.dart
        │   ├── playlists_screen.dart
        │   ├── settings_screen.dart
        │   └── songs_screen.dart
        ├── shell/
        │   └── home_shell.dart
        └── widgets/
            ├── mini_player_bar.dart
            └── mini_song_tile.dart
```

---

## Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android SDK or Xcode (for iOS)

### Installation
```bash

# Clone the repository
git clone https://github.com/ImranHasan134/ezze_music.git

# Navigate to project directory
cd ezze_music

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## Permissions

### Android
The following permissions are required and declared in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
```

### iOS
The following keys are required in `Info.plist`:
```xml
<key>NSAppleMusicUsageDescription</key>
<string>EzzeMusic needs access to your music library.</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

---

## Design System

| Token | Value | Usage |
|---|---|---|
| `_bgDeep` | `#0D0D14` | Main background |
| `_bgGlass` | `#1E1E2A` | Cards, sheets, nav bar |
| `_accent` | `#FF6B35` | Primary accent, active states |
| `_textPrimary` | `#F0F0F5` | Titles, primary text |
| `_textSecondary` | `#8A8A9A` | Subtitles, descriptions |
| `_textMuted` | `#4A4A5A` | Labels, inactive icons |
| `_divider` | `#252530` | Borders, separators |

---

## Contributing

Pull requests are welcome. For major changes please open an issue first to discuss what you would like to change.

---

## Developer

Built with ❤️ by **Imran Hasan**
