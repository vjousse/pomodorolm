# Screenshot

![Screenshot of the app](screenshot.png)

# Installation

## Archlinux

    yay -S pomodorolm-bin

## Windows, Mac OS X, Debian, AppImage

Download the install file for your OS from the latest release on https://github.com/vjousse/pomodorolm/releases/

# Dev

You will need to [install rust](https://www.rust-lang.org/tools/install) first.

    npm i

## Running the app

    npm run tauri dev

## Running only the webapp

    npm run dev

# Build

Build using `docker-compose` (to maximize compatibily, normal build is failing on Archlinux for example):

    docker-compose up

Build files will be placed in the `target/` directory.

# Credits

Design taken from https://github.com/Splode/pomotroid
