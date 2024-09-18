# Snapcraft

## Build

    snapcraft -v --debug

## Install

    sudo snap install ./pomodorolm_0.1.5_amd64.snap --dangerous --devmode

## Run

    snap run pomodorolm

## Webkit error

Happens only for developers locally.

    ** (process:172251): ERROR **: 23:34:35.683: Unable to spawn a new child process: Failed to spawn child process “/usr/lib/webkitgtk-4.1/WebKitNetworkProcess” (No such file or directory)

To fix it run:

    sudo /usr/lib/snapd/snap-discard-ns pomodorolm
