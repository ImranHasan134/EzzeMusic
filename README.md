# EzzeMusic 🎵

A high-performance, premium local music player built with Flutter. EzzeMusic offers a "Luxury Dark" experience, now optimized with background processing (Isolates) and dynamic personalization to ensure a butter-smooth experience even on mid-range devices.

---

## 🚀 New & Optimized Features

### ⚡ Performance & Stability
- **Isolate-Powered Library**: Scanning and filtering thousands of songs is offloaded to a background thread (`compute`), preventing "Application Not Responding" (ANR) errors.
- **Instant RAM Caching**: The library is scanned once at startup and cached. Toggling filters or searching is now instantaneous.
- **Stability Patch**: Background blurs are optimized with lower GPU overhead and `RepaintBoundary` wrappers to maintain 60FPS during animations.

### 🔍 Discovery
- **Real-Time Search**: Instant filtering by song title or artist as you type.
- **Pull-to-Refresh**: A smooth, native gesture to force a deep storage rescan for newly downloaded music.
- **Smart Filtering**: Optional "Hide Short Clips" mode that strictly shows `.mp3` files longer than 30 seconds to keep your library clean.

### 💿 Premium Now Playing UI
- **Vinyl Spin Animation**: The artwork is now a perfect circle that slowly rotates like a physical record when music is playing.
- **Dynamic Glow**: A soft "halo" effect behind the artwork that pulses gently in sync with the track.
- **Perfect Circle Clipping**: Uses `ClipOval` and a Stack-based rim overlay to ensure perfectly smooth edges with no square "leakage."

### 🎨 Personalization
- **Dynamic Accent Engine**: Choose from a curated palette (Indigo, Rose, Gold, Emerald, etc.). The entire app’s highlights, glows, and icons update instantly.
- **Luxury Glassmorphism**: Cards and navigation elements use a subtle border-stroke and semi-transparent "glass" background.

---

## Features

### 🎵 Playback
- Background playback with lock screen integration.
- Play/Pause, Next, Previous, Shuffle, and Repeat modes.
- Seek bar with real-time position tracking.
- Sleep timer (15 min, 30 min, 1 hour).
- State restoration: Automatically remembers your last played song and queue.

### 🎶 Playlists & Favourites
- Create, rename, and delete custom playlists.
- One-tap "Favourite" system with a dedicated animated heart toggle.
- Add/remove songs from playlists via a premium bottom-sheet interface.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Latest Stable) |
| **Concurrency** | `Isolates` (`compute`) for background filtering |
| **Audio Engine** | `just_audio` & `just_audio_background` |
| **State** | `provider` (Reactive Architecture) |
| **Persistence** | `shared_preferences` & `json_serialization` |
| **UI Polish** | `marquee`, `on_audio_query`, `Animations` |

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
            ├── mini_song_tile.dart
            └── now_playing_thumbnail.dart
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

| Token | Value      | Usage                     |
|---|------------|---------------------------|
| `_bgDeep` | `#09090B`  | Deepest background layer  |
| `_bgGlass` | `#18181B`  | Themed containers & bars  |
| `_accent` | `Dynamic`  | User-defined (Rose, Gold, Emerald, etc.) |
| `_textPrimary` | `#F0F0F5`  | Titles, primary text      |
| `_textSecondary` | `#8A8A9A`  | Subtitles, descriptions   |
| `_textMuted` | `#4A4A5A`  | Labels, inactive icons    |
| `_divider` | `#252530`  | Borders, separators       |

---

## Contributing

Pull requests are welcome. For major changes please open an issue first to discuss what you would like to change.

---

## 👨🏻‍💻 Developer

Built by **MD. Imran Hasan**
