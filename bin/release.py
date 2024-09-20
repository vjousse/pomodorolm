#!/usr/bin/env python

import argparse
import hashlib
import json
import pathlib
import urllib.request
import xml.etree.ElementTree as ET

import fileinput
import yaml

METAINFO = "org.jousse.vincent.Pomodorolm.metainfo.xml"
PACKAGE_JSON = "package.json"
SNAPCRAFT = "snapcraft.yaml"
TAURI_CONF = "src-tauri/tauri.conf.json"
AUR_PKGBUILD = "aur/PKGBUILD"

tauri_version = None
snapcraft_version = None
package_json_version = None
metainfo_version = None
aur_version = None
aur_source = None
aur_sha256 = None

parser = argparse.ArgumentParser(
    description="Check the coherence of files containing version information."
)
parser.add_argument("--version", help="The version you want to publish", type=str)
parser.add_argument(
    "--update-aur-checksum",
    help="Download the release from Github, compute the checksum and override it in PKGBUILD",
    action="store_true",
)

args = parser.parse_args()


versions = []

with open(TAURI_CONF, "r") as tauri_file:
    tauri_json = json.load(tauri_file)
    tauri_version = tauri_json["version"]

    versions.append({"source": TAURI_CONF, "version": tauri_version})

with open(SNAPCRAFT, "r") as snapcraft_file:
    snapcraft_yaml = yaml.safe_load(snapcraft_file)
    snapcraft_version = snapcraft_yaml["version"]
    versions.append({"source": SNAPCRAFT, "version": snapcraft_version})

with open(PACKAGE_JSON, "r") as package_json_file:
    package_json = json.load(package_json_file)
    package_version = package_json["version"]
    versions.append({"source": PACKAGE_JSON, "version": package_version})


with open(AUR_PKGBUILD, "r") as aur_pkgbuild_file:
    for line in aur_pkgbuild_file.readlines():
        if line.startswith("pkgver="):
            aur_version = line.split("=")[1].strip()

        if line.startswith("source="):
            aur_source = line.split('"')[1].strip()

        if line.startswith("sha256sums="):
            aur_sha256 = line.split("'")[1].strip()

    versions.append({"source": AUR_PKGBUILD, "version": aur_version})

tree = ET.parse(METAINFO)
root = tree.getroot()

latest_metainfo_version = root.find("releases").find("release").attrib["version"]

versions.append({"source": "metainfo", "version": latest_metainfo_version})


if args.update_aur_checksum:
    print(f"--> Updating AUR checksum {aur_source}")
    url = aur_source.replace("${pkgver}", aur_version).replace("$pkgver", aur_version)
    print(f"--> Downloading {url}")
    tmp_file = "pomodorolm.deb"

    urllib.request.urlretrieve(url, tmp_file)
    sha256 = ""
    with open(tmp_file, "rb", buffering=0) as f:
        sha256 = hashlib.file_digest(f, "sha256").hexdigest()

    print(f"--> SHA256: {sha256}")
    if sha256 != aur_sha256:
        print(
            f"--> Sha sums are different. Computed : {sha256}, in PKGBUILD: {aur_sha256}, updating."
        )
        pass

        for line in fileinput.input(AUR_PKGBUILD, inplace=True):
            if line.startswith("sha256sums="):
                print(f"sha256sums=('{sha256}')", end="")
            else:
                print(line, end="")
    else:
        print("--> SHA is up to date PKGBUILD, nothing to do.")

    pathlib.Path.unlink(tmp_file)
    exit(0)


if args.version:
    version_to_check = args.version
else:
    print(
        "--> No version specified in parameters, reading version from `src-tauri/tauri.conf.json`"
    )
    version_to_check = tauri_version

all_versions_are_the_same = all(
    version["version"] == version_to_check for version in versions
)

if all_versions_are_the_same:
    print(
        f"--> 🎉 Your files are coherent, ready to publish version `{version_to_check}`"
    )
    exit(0)
else:
    print(f"--> 🚨 Some versions differ from `{version_to_check}`:")

    for version in versions:
        if version["version"] != version_to_check:
            print(json.dumps(version, indent=2))

    exit(1)
