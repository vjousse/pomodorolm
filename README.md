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
- [x] **Built-in [themes](#-themes)**
- [x] **Custom [themes](#-themes)**
- [x] **Color gradient** depending on the remaining time
- [x] **Tray icon** with color gradient
- [x] **Minimize to tray** (optional)
- [x] **Tick and end sounds** (optional)
- [x] **Multi-platform**: Linux, Mac, Windows
- [x] **Resizable window** with automatic scaling
- [x] **Always on top** (optional)
- [x] Fully compatible with **HiDPI/4K screens**
- [x] Linux: **Wayland** and **X11** support
- [x] Small: size < 4Mb (no electron, no node)
- [ ] Mini mode
- [ ] Terminal User Interface
- [ ] Mobile version

# 📘 Installation

## Archlinux

    yay -S pomodorolm-bin

## Windows, Mac OS X, Debian, AppImage

Download the install file for your OS from the latest release on https://github.com/vjousse/pomodorolm/releases/

# 🎨 Themes

Pomodorolm provides many themes. It's also theme-able, allowing you to customize its appearance.

![Screenshots of Pomotroid using various themes](./.github/images/pomotroid_themes-preview--914x219.png)

Visit the [theme documentation](./docs/themes/themes.md) to view the full list of official themes and for instruction on creating your own.

# 💻 Dev

You will need to [install rust](https://www.rust-lang.org/tools/install) first.

    npm ci

## Running the app

    npm run tauri dev

## Running only the webapp

    npm run dev

# 🔨 Build

If you're using Linux be sure to set the `NO_STRIP` env var to `true` (see https://github.com/tauri-apps/tauri/issues/8929 ) if the build is failing.

    NO_STRIP=true npm run tauri build -- --target x86_64-unknown-linux-gnu

If the build is still failing try to understand why using:

    NO_STRIP=true npm run tauri build -- --target x86_64-unknown-linux-gnu --verbose

You can also try to build using `docker-compose` (to maximize compatibility, normal build is failing on Archlinux for example):

    docker-compose run --rm --build build-linux

Build files will be placed in the `target/` directory.

# 💀 Troubleshooting

## Linux

### `Failed to create GBM buffer of size…`

If you run into this error, it is likely because you're using nvidia drivers under Linux. They are several bug reports in Webkit, cf this issue for wails: https://github.com/wailsapp/wails/issues/2977#issuecomment-1791041741.

You can try to run `pomodorolm` using this command:

    WEBKIT_DISABLE_DMABUF_RENDERER=1 pomodorolm

Thanks to @Bad3r for the [bug report](https://github.com/vjousse/pomodorolm/issues/62)!

## Windows

### App starts and then closes immediately or doesn't start at all

Check that your antivirus (Windows defender or whatever antivirus you are using) doesn't report the app as a trojan. Unfortunately, there is a known issue https://github.com/tauri-apps/tauri/issues/2486 on Tauri where a false positive is reported when executing apps generated with Tauri on Windows.

# 💯 Credits

Thanks to https://github.com/Splode/pomotroid for the original design and ideas.
