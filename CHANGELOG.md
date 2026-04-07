# Changelog

All notable changes to this project will be documented in this file.

## [[app-v0.9.0](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.9.0)] - 2026-04-07

### 🚀 Features

- Add volume option ([#224](https://github.com/vjousse/pomodorolm/issues/224))

### 📚 Documentation

- Add no IAgen policy

### ⚙️ Miscellaneous Tasks

- Not spawn play_sound_file if playing is muted ([#217](https://github.com/vjousse/pomodorolm/issues/217))
- Small optimization and refactor of create_icon  ([#221](https://github.com/vjousse/pomodorolm/issues/221))

## [[app-v0.8.0](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.8.0)] - 2026-01-23

### 🚀 Features

- *(win,mac)* Show app on tray double click ([#210](https://github.com/vjousse/pomodorolm/issues/210))

### 🐛 Bug Fixes

- Use exe for winget ([#213](https://github.com/vjousse/pomodorolm/issues/213))
- Reset session should go back to focus ([#214](https://github.com/vjousse/pomodorolm/issues/214))

### 📚 Documentation

- Add winget instructions ([#208](https://github.com/vjousse/pomodorolm/issues/208))

### ⚙️ Miscellaneous Tasks

- Add winget release action ([#211](https://github.com/vjousse/pomodorolm/issues/211))
- Update bump script to avoid parsing warnings
- Bump to 0.8.0

## [[app-v0.7.0](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.7.0)] - 2025-11-28

### 🚀 Features

- Configure max session length ([#203](https://github.com/vjousse/pomodorolm/issues/203))
- Add reset session button ([#204](https://github.com/vjousse/pomodorolm/issues/204))

### ⚙️ Miscellaneous Tasks

- Update AUR checksum
- Update deps ([#201](https://github.com/vjousse/pomodorolm/issues/201))
- Bump to 0.7.0

## [[app-v0.6.2](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.6.2)] - 2025-11-21

### 🐛 Bug Fixes

- Handle play status correctly in tray menu ([#199](https://github.com/vjousse/pomodorolm/issues/199))
- Handle always on top config ([#200](https://github.com/vjousse/pomodorolm/issues/200))

### ⚙️ Miscellaneous Tasks

- Update aur package
- Update to latest deps and tauri 2.8 ([#191](https://github.com/vjousse/pomodorolm/issues/191))
- Bump to 0.6.2

## [[app-v0.6.1](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.6.1)] - 2025-10-01

### 🐛 Bug Fixes

- App crash if duration is 0 ([#188](https://github.com/vjousse/pomodorolm/issues/188))
- No icon on windows 11 ([#189](https://github.com/vjousse/pomodorolm/issues/189))

### ⚙️ Miscellaneous Tasks

- Bump to 0.6.1

## [[app-v0.6.0](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.6.0)] - 2025-08-08

### 🚀 Features

- Edit current and default session labels ([#174](https://github.com/vjousse/pomodorolm/issues/174))
- Add autostart and autoquit ([#178](https://github.com/vjousse/pomodorolm/issues/178))

### 🐛 Bug Fixes

- Play all custom sounds ([#183](https://github.com/vjousse/pomodorolm/issues/183))

### ⚙️ Miscellaneous Tasks

- Bump to 0.6.0

## [[app-v0.5.0](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.5.0)] - 2025-05-23

### 🚀 Features

- Ensure only one instance is running ([#171](https://github.com/vjousse/pomodorolm/issues/171))
- Add minimal CLI version ([#146](https://github.com/vjousse/pomodorolm/issues/146))

### ⚙️ Miscellaneous Tasks

- Update AUR checksum for 0.4.0
- Bump to 0.5.0

## [[app-v0.4.0](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.4.0)] - 2025-05-11

### 🚀 Features

- Add system auto start ([#168](https://github.com/vjousse/pomodorolm/issues/168))
- Add start minimized to tray option ([#169](https://github.com/vjousse/pomodorolm/issues/169))

### ⚙️ Miscellaneous Tasks

- Bump to 0.4.0

## [[app-v0.3.6](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.3.6)] - 2025-04-18

### ⚙️ Miscellaneous Tasks

- Update deps ([#164](https://github.com/vjousse/pomodorolm/issues/164))
- Bump to 0.3.6

## [[app-v0.3.5](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.3.5)] - 2025-03-14

### 🐛 Bug Fixes

- Update pomodoro config on config change ([#152](https://github.com/vjousse/pomodorolm/issues/152))
- Notification settings ([#161](https://github.com/vjousse/pomodorolm/issues/161))

### 📚 Documentation

- Add macOS troubleshooting section ([#153](https://github.com/vjousse/pomodorolm/issues/153))

### ⚙️ Miscellaneous Tasks

- Bump 0.3.5

## [[app-v0.3.4](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.3.4)] - 2025-01-22

### ⚙️ Miscellaneous Tasks

- Update AUR checksum
- Update to latest Tauri ([#150](https://github.com/vjousse/pomodorolm/issues/150))
- Bump version to 0.3.4

## [[app-v0.3.3](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.3.3)] - 2025-01-11

### 🐛 Bug Fixes

- Bad pause icon rendering ([#144](https://github.com/vjousse/pomodorolm/issues/144))

### ⚙️ Miscellaneous Tasks

- Bump version to 0.3.3

## [[app-v0.3.2](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.3.2)] - 2025-01-11

### 🐛 Bug Fixes

- *(Arch Linux)* Add `libayatana-appindicator` as dependency in PKGBUILD ([#137](https://github.com/vjousse/pomodorolm/issues/137)) ([#138](https://github.com/vjousse/pomodorolm/issues/138))
- Move PKGBUILD in its own directory ([#139](https://github.com/vjousse/pomodorolm/issues/139))
- Sound on ubuntu with snapcraft ([#143](https://github.com/vjousse/pomodorolm/issues/143))

### 🎨 Styling

- Add catppuccin latte and mocha ([#140](https://github.com/vjousse/pomodorolm/issues/140))
- Implement all catppuccin themes ([#141](https://github.com/vjousse/pomodorolm/issues/141))

### ⚙️ Miscellaneous Tasks

- Upgrade gh workflow ([#142](https://github.com/vjousse/pomodorolm/issues/142))
- Bump version number to 0.3.2

## [[app-v0.3.1](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.3.1)] - 2024-11-07

### 🐛 Bug Fixes

- LibOSSlib.so not found in snap ([#130](https://github.com/vjousse/pomodorolm/issues/130))
- Mac osx hide behavior ([#132](https://github.com/vjousse/pomodorolm/issues/132))

### ⚙️ Miscellaneous Tasks

- Update AUR checksum
- Bump version to 0.3.1

## [[app-v0.3.0](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.3.0)] - 2024-11-06

### 🚀 Features

- Customize notification sounds ([#127](https://github.com/vjousse/pomodorolm/issues/127))

### 🚜 Refactor

- Manage state on the rust side ([#112](https://github.com/vjousse/pomodorolm/issues/112))
- Simplify resource resolving ([#120](https://github.com/vjousse/pomodorolm/issues/120))

### 📚 Documentation

- Add a workaround for flatpak and nvidia ([#118](https://github.com/vjousse/pomodorolm/issues/118))
- Add instructions for flatpak

### ⚙️ Miscellaneous Tasks

- Update to stable Tauri v2 ([#116](https://github.com/vjousse/pomodorolm/issues/116))
- Create issue template ([#124](https://github.com/vjousse/pomodorolm/issues/124))
- Update to Tauri stable ([#128](https://github.com/vjousse/pomodorolm/issues/128))
- Bump to 0.3.0

## [[app-v0.2.2](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.2.2)] - 2024-10-16

### 🐛 Bug Fixes

- Focus notification time ([#126](https://github.com/vjousse/pomodorolm/issues/126))

## [[app-v0.2.1](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.2.1)] - 2024-09-29

### 🐛 Bug Fixes

- Load themes and config synchronously ([#110](https://github.com/vjousse/pomodorolm/issues/110))
- Aur sha computation

### ⚙️ Miscellaneous Tasks

- Bump version to 0.2.1

## [[app-v0.2.0](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.2.0)] - 2024-09-27

### 🚀 Features

- Add script to update PKGBUILD
- Add toggle-play and skip ([#107](https://github.com/vjousse/pomodorolm/issues/107))
- Use git-cliff in release script ([#108](https://github.com/vjousse/pomodorolm/issues/108))

### 🐛 Bug Fixes

- Snapcraft build
- Snapcraft builds
- Remove version check for now

### 📚 Documentation

- Add flathub link
- Add Snap Store badge
- Add CHANGELOG.md

### ⚙️ Miscellaneous Tasks

- Add version 0.1.11
- Add snapcraft build ([#77](https://github.com/vjousse/pomodorolm/issues/77))
- Update version in snapcraft
- Update flatpak build
- Add screenshots
- Check versions consistency when releasing ([#89](https://github.com/vjousse/pomodorolm/issues/89))
- Add flatpak build to github actions ([#91](https://github.com/vjousse/pomodorolm/issues/91))
- Add snapcraft build ([#93](https://github.com/vjousse/pomodorolm/issues/93))
- Rename flatpak workflow
- Add AUR PKGBUILD
- Check Cargo.toml version
- Upgrade to latest Tauri RC 15 ([#95](https://github.com/vjousse/pomodorolm/issues/95))
- Update pkgrel
- Add pre-commit ([#102](https://github.com/vjousse/pomodorolm/issues/102))
- Add elm-review ([#104](https://github.com/vjousse/pomodorolm/issues/104))
- Fix snapcraft build ([#105](https://github.com/vjousse/pomodorolm/issues/105))
- Bump version to 0.2.0
- Fix check-versions workflow
- Add missing git-cliff
- Install git-cliff using cargo

## [[app-v0.1.11](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.1.11)] - 2024-09-13

### 🐛 Bug Fixes

- Windows icon and launching issue ([#85](https://github.com/vjousse/pomodorolm/issues/85))

### 📚 Documentation

- Update README with windows error

### ⚙️ Miscellaneous Tasks

- Flathub build on aarch64 ([#86](https://github.com/vjousse/pomodorolm/issues/86))
- Bump version number to 0.1.11

## [[app-v0.1.10](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.1.10)] - 2024-09-11

### ⚙️ Miscellaneous Tasks

- Offline flatpak build ([#84](https://github.com/vjousse/pomodorolm/issues/84))
- Bump version number to 0.1.10

## [[app-v0.1.9](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.1.9)] - 2024-09-09

### 🐛 Bug Fixes

- *(flatpak)* Sync yarn packages

### 📚 Documentation

- Flatpak build tools

### ⚙️ Miscellaneous Tasks

- Build app directly in flatpak ([#83](https://github.com/vjousse/pomodorolm/issues/83))
- Bump version to 0.1.9

## [[app-v0.1.8](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.1.8)] - 2024-09-06

### 🐛 Bug Fixes

- Display (broken) sys tray icon for flatpak

### 📚 Documentation

- Flatpak README

### ⚙️ Miscellaneous Tasks

- Change LICENSE to AGPL
- Add flatpak build ([#78](https://github.com/vjousse/pomodorolm/issues/78))
- Bump version to 0.1.8

## [[app-v0.1.7](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.1.7)] - 2024-08-30

### 🐛 Bug Fixes

- Change theme only on config load ([#81](https://github.com/vjousse/pomodorolm/issues/81))
- Change theme on config load
- Remove debug
- Flatpak sound

### ⚙️ Miscellaneous Tasks

- Update version to 0.1.7

## [[app-v0.1.6](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.1.6)] - 2024-08-30

### 🚜 Refactor

- Better error management ([#72](https://github.com/vjousse/pomodorolm/issues/72))

### 📚 Documentation

- Update README

### ⚙️ Miscellaneous Tasks

- Upgrade to tauri-rc.7 ([#73](https://github.com/vjousse/pomodorolm/issues/73))
- Upgrade to tauri rc 8 ([#79](https://github.com/vjousse/pomodorolm/issues/79))
- Version 0.1.6

## [[app-v0.1.5](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.1.5)] - 2024-08-20

### 🚀 Features

- Add theming support ([#69](https://github.com/vjousse/pomodorolm/issues/69))

### 🐛 Bug Fixes

- Remove Elm debug

### 📚 Documentation

- Npm ci
- Add troubleshooting section ([#64](https://github.com/vjousse/pomodorolm/issues/64))
- Remove useless backticks

### ⚙️ Miscellaneous Tasks

- Bump version number

## [[app-v0.1.4](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.1.4)] - 2024-07-26

### ⚙️ Miscellaneous Tasks

- Split code into separate files ([#61](https://github.com/vjousse/pomodorolm/issues/61))
- Update to latest tauri beta-24 ([#63](https://github.com/vjousse/pomodorolm/issues/63))
- Bump version number

## [[app-v0.0.6](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.0.6)] - 2024-05-23

### ⚙️ Miscellaneous Tasks

- Update version number to 0.0.6

## [[app-v0.0.5](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.0.5)] - 2024-05-21

### 🐛 Bug Fixes

- Play notification at the end of the round ([#34](https://github.com/vjousse/pomodorolm/issues/34))

### ⚙️ Miscellaneous Tasks

- Bump version to 0.0.5

## [[app-v0.0.4](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.0.4)] - 2024-05-21

### 🚀 Features

- Add version number ([#33](https://github.com/vjousse/pomodorolm/issues/33))

### 🐛 Bug Fixes

- Minimize to tray on close ([#32](https://github.com/vjousse/pomodorolm/issues/32))
- Formatting

### ⚙️ Miscellaneous Tasks

- Update arch PKGBUILD
- Bump version number

## [[app-v0.0.3](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.0.3)] - 2024-05-16

### 🚀 Features

- Add build-only github action

### 🐛 Bug Fixes

- Manage tick on the rust side ([#28](https://github.com/vjousse/pomodorolm/issues/28))

## [[app-v0.0.2](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.0.2)] - 2024-04-30

### 🚀 Features

- Add Archlinux PKGBUILD ([#20](https://github.com/vjousse/pomodorolm/issues/20))

### 🐛 Bug Fixes

- Binary name ([#16](https://github.com/vjousse/pomodorolm/issues/16))
- Binary name ([#17](https://github.com/vjousse/pomodorolm/issues/17))
- Archlinux package name
- Specify draggable region ([#22](https://github.com/vjousse/pomodorolm/issues/22))

### ⚙️ Miscellaneous Tasks

- Clippy all the things 🎉 ([#18](https://github.com/vjousse/pomodorolm/issues/18))
- Update README with releases ([#21](https://github.com/vjousse/pomodorolm/issues/21))

## [[app-v0.0.1](https://github.com/vjousse/pomodorolm/releases/tag/app-v0.0.1)] - 2024-04-26

### 🐛 Bug Fixes

- Windows build doesn't support alpha version ([#14](https://github.com/vjousse/pomodorolm/issues/14))

## [[0.0.1-alpha](https://github.com/vjousse/pomodorolm/releases/tag/0.0.1-alpha)] - 2024-04-26

### 🚀 Features

- Add github workflow for release build

### ⚙️ Miscellaneous Tasks

- Specify alpha version ([#13](https://github.com/vjousse/pomodorolm/issues/13))

<!-- generated by git-cliff -->
