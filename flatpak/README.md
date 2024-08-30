# flatpak

## Build

    flatpak-builder --force-clean --user --repo=repo --install builddir org.jousse.vincent.Pomodorolm.yml

## Run

    flatpak run org.jousse.vincent.Pomodorolm.yml

## Lint

    flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest org.jousse.vincent.Pomodorolm.yml
