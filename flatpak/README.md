# flatpak

## Build

    flatpak-builder --force-clean --user --repo=repo --install builddir org.jousse.vincent.Pomodorolm.yml

## Run

    flatpak run org.jousse.vincent.Pomodorolm

## Lint

    flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest org.jousse.vincent.Pomodorolm.yml

## Debug

    flatpak run --command=bash --socket=pulseaudio org.jousse.vincent.Pomodorolm

## Links

- https://github.com/axolotl-chat/axolotl/blob/main/flatpak/org.nanuc.Axolotl.yml
- https://github.com/tauri-apps/tauri/discussions/4426
