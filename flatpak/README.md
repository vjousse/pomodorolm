# flatpak

## Build

    flatpak-builder --force-clean --user --repo=repo --install builddir org.jousse.vincent.Pomodorolm.yml

## Run

    flatpak run org.jousse.vincent.Pomodorolm

## Lint

    flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest org.jousse.vincent.Pomodorolm.yml

## Debug

    flatpak run --command=bash --socket=pulseaudio org.jousse.vincent.Pomodorolm

## Generate dependencies

Use https://github.com/flatpak/flatpak-builder-tools

    python ~/usr/src/python/flatpak-builder-tools/cargo/flatpak-cargo-generator.py -d ./src-tauri/Cargo.lock -o flatpak/cargo-sources.json

Before running the node generator for `npm`, be sure to `rm -rf node_modules` or it will fail to generate the file properly.

    flatpak-node-generator npm -o flatpak/node-sources.json package-lock.json

## Elm

### Generate `elm-sources.json`

    ./flatpak-elm-generator.py ../elm.json elm-sources.json

### Get registry.dat

In the project root directory:

    rm -rf elm-stuff && ELM_HOME=tmp npx elm make src-elm/Main.elm
    cp tmp/0.19.1/packages/registry.dat flatpak
    rm -rf tmp

## Links

- https://github.com/axolotl-chat/axolotl/blob/main/flatpak/org.nanuc.Axolotl.yml
- https://github.com/tauri-apps/tauri/discussions/4426
- https://github.com/flathub/com.nextcloud.desktopclient.nextcloud/blob/518e7c06718f211966a6231a87e57090968e911d/org.nextcloud.Nextcloud.yml
- https://github.com/CodeMouse92/Timecard/blob/main/com.codemouse92.timecard.yaml
- systray problem: https://bbs.archlinux.org/viewtopic.php?id=286513
- https://github.com/zed-industries/zed/pull/13098
- https://github.com/flathub/shared-modules/issues/223
- https://github.com/flathub/org.keepassxc.KeePassXC/issues/58
- https://github.com/zocker-160/SyncThingy
- https://github.com/flathub/com.modrinth.ModrinthApp

Tray icons sucks - https://blog.tingping.se/2019/09/07/how-to-design-a-modern-status-icon.html

To make ELM local cache: https://github.com/robx/shelm
