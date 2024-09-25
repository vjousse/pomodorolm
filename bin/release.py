#!/usr/bin/env python

import argparse
import datetime
import fileinput
import hashlib
import json
import pathlib
import subprocess as sp
import urllib.request
import xml.etree.ElementTree as ET

import tomllib
import yaml
from packaging.version import Version

METAINFO = "org.jousse.vincent.Pomodorolm.metainfo.xml"
PACKAGE_JSON = "package.json"
PACKAGE_LOCK_JSON = "package-lock.json"
SNAPCRAFT = "snapcraft.yaml"
TAURI_CONF = "src-tauri/tauri.conf.json"
CARGO_TOML = "src-tauri/Cargo.toml"
AUR_PKGBUILD = "aur/PKGBUILD"

metainfo_first_version = Version("0.1.8")

tauri_version = None
cargo_version = None
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

with open(CARGO_TOML, "rb") as f:
    cargo_toml = tomllib.load(f)
    cargo_version = cargo_toml["package"]["version"]
    versions.append({"source": CARGO_TOML, "version": cargo_version})

with open(SNAPCRAFT, "r") as snapcraft_file:
    snapcraft_yaml = yaml.safe_load(snapcraft_file)
    snapcraft_version = snapcraft_yaml["version"]
    versions.append({"source": SNAPCRAFT, "version": snapcraft_version})

with open(PACKAGE_JSON, "r") as package_json_file:
    package_json = json.load(package_json_file)
    package_version = package_json["version"]
    versions.append({"source": PACKAGE_JSON, "version": package_version})

with open(PACKAGE_LOCK_JSON, "r") as package_lock_json_file:
    package_lock_json = json.load(package_lock_json_file)
    package_lock_version = package_lock_json["version"]
    versions.append({"source": PACKAGE_LOCK_JSON, "version": package_lock_version})


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


metainfo_releases = {}

for release in root.find("releases"):
    metainfo_releases[release.attrib["version"]] = release.attrib["date"]


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

git_cliff_output = json.loads(sp.getoutput("git-cliff --bump --context"))

git_cliff_releases = {}
latest_git_cliff_version = None

for release in git_cliff_output:
    date = datetime.datetime.fromtimestamp(release["timestamp"]).strftime("%Y-%m-%d")
    version = release["version"]
    stripped_version = version.replace("app-v", "")

    if latest_git_cliff_version is None:
        latest_git_cliff_version = stripped_version

    if (
        Version(stripped_version) >= metainfo_first_version
        and stripped_version not in metainfo_releases
    ):
        print(f"--> ⚠️ Version {stripped_version} is missing in metainfo.xml")


if args.version:
    version_to_check = args.version
else:
    print(
        f"--> ℹ️ No version specified in parameters, reading version from `src-tauri/tauri.conf.json`: {tauri_version}"
    )
    version_to_check = tauri_version

all_versions_are_the_same = all(
    version["version"] == version_to_check for version in versions
)

if all_versions_are_the_same and version_to_check == latest_git_cliff_version:
    print(
        f"--> 🎉 Your files are coherent, ready to publish version `{version_to_check}`"
    )
    exit(0)
else:
    if version_to_check != latest_git_cliff_version:
        print(
            f"--> 🚨 Git cliff found a new version `{latest_git_cliff_version}` that is different from `{version_to_check}`, you should probably bump your version number."
        )

    if not all_versions_are_the_same:
        print(f"--> 🚨 Some versions differ from `{version_to_check}`:")

        for version in versions:
            if version["version"] != version_to_check:
                print(json.dumps(version, indent=2))

    exit(1)
