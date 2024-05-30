<!-- logo -->
<p align="center">
  <img src="src-tauri/icons/128x128.png">
</p>

<!-- tag line -->
<h2 align='center'>Pomodorolm<br />simple yet powerful time tracker</h3>
<br/>
<br/>

---

![Screenshot of the app](screenshot.png?)

# 🌟 Features

- [x] **Customize round numbers, focus and break times**
- [x] **Auto-start round** (optional)
- [x] **Desktop notifications** (optional)
- [x] **Color gradiant** depending on the remaining time
- [x] **Tray icon** with color gradiant
- [x] **Minimize to tray** (optional)
- [x] **Tick and end sounds** (optional)
- [x] **Multi-platform**: Linux, Mac, Windows
- [x] **Resizable window** with automatic scaling
- [x] **Always on top** (optional)
- [x] Fully compatible with **HiDPI/4K screens**
- [x] Linux: **Wayland** and **X11** support
- [ ] Mini mode
- [ ] Terminal User Interface
- [ ] Mobile version

# 📘 Installation

## Archlinux

    yay -S pomodorolm-bin

## Windows, Mac OS X, Debian, AppImage

Download the install file for your OS from the latest release on https://github.com/vjousse/pomodorolm/releases/

# 💻 Dev

You will need to [install rust](https://www.rust-lang.org/tools/install) first.

    npm i

## Running the app

    npm run tauri dev

## Running only the webapp

    npm run dev

# 🔨 Build

Build using `docker-compose` (to maximize compatibily, normal build is failing on Archlinux for example):

    docker-compose up

Build files will be placed in the `target/` directory.

# 💯 Credits

Thanks to https://github.com/Splode/pomotroid for the original design and ideas
