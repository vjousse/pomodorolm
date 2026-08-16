#!/usr/bin/env bash


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$( dirname $SCRIPT_DIR )

uv run $ROOT_DIR/bin/flatpak-cargo-generator.py -d $ROOT_DIR/src-tauri/Cargo.lock -o $ROOT_DIR/flatpak/cargo-sources.json

# It seems that if the `node_module` dir is not empty the script doesn’t work as expected
echo "Deleting $ROOT_DIR/node_modules/*"
rm -rf $ROOT_DIR/node_modules/*
uv run flatpak-node-generator npm -o $ROOT_DIR/flatpak/node-sources.json $ROOT_DIR/package-lock.json
