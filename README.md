<div align="center">
  <img src="assets/icon/app_icon.png" alt="EzzeMusic Logo" width="150" height="150" style="border-radius: 20px;" />

  <h1>🎵 EzzeMusic (A Ezze Softwares Product)</h1>
  <p><b>A premium, fluid, and beautifully crafted offline music player for Android & iOS.</b></p>
  <p><i>Developed by <b>MD. Imran Hasan</b></i></p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge" />
    <img src="assets/icon/splash.gif" />
    
  </p>
</div>

---

## ✨ Overview

**EzzeMusic** is not just another music player. It is designed with a strong focus on **motion design, luxury aesthetics, and seamless user experience**.

Built entirely in Flutter, it scans your local audio library and presents it through a stunning **dark-themed, glassmorphic UI**.

From the floating navigation bar to the rotating vinyl on the Now Playing screen, every interaction is crafted with precision, smooth physics, and haptic feedback.

---

## 🚀 Key Features

### 🎨 Premium UI & Motion Design
- Dynamic accent colors (8+ themes)
- Glassmorphism UI with blur & depth
- Smooth animations using `easeOutBack` & `easeInOutCubic`
- Haptic feedback for key interactions

### 🎧 Core Audio Experience
- Smart local file scanning (MP3, M4A, etc.)
- Filters out short audio (< 30 sec)
- Vinyl-style Now Playing screen
- Smooth metadata transitions (`AnimatedSwitcher`)
- Background playback support

### 📁 Library & Playlists
- Custom playlist creation & management
- One-tap Favorites system ❤️
- Instant queue & playback control

---

## 🛠️ Tech Stack & Packages

- **State Management:** `provider`
- **Audio Engine:** `just_audio`
- **Local Storage:** `shared_preferences` *(planned SQLite upgrade)*
- **File Access:** `on_audio_query`

### UI Libraries
- `marquee` (scrolling text)
- `just_audio_background` (media controls)

---

## 📂 Project Structure

```
lib/
├── data/
├── models/
├── state/
├── ui/
│   ├── screens/
│   └── widgets/
└── main.dart
```

---

## 🗺️ Roadmap

- SQLite migration for large libraries
- Global search with animation
- Built-in equalizer & audio effects

---

## 📄 License

This project is proprietary software developed by **Ezze Softwares**. All rights reserved.

---
