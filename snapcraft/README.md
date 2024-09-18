# Snapcraft

## Build

    snapcraft -v --debug

## Install

    sudo snap install ./pomodorolm_0.1.5_amd64.snap --dangerous --devmode

## Run

    snap run pomodorolm

## Webkit error

Happens only for developers locally.

    ** (pomodorolm:364934): ERROR **: 11:34:14.245: Unable to spawn a new child process: Failed to spawn child process “/usr/lib/x86_64-linux-gnu/webkit2gtk-4.1/WebKitNetworkProcess” (No such file or directory)

To fix it run:

    sudo /usr/lib/snapd/snap-discard-ns pomodorolm
