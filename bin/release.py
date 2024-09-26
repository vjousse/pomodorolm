#!/usr/bin/env python

import dataclasses
import datetime
import fileinput
import hashlib
import json
import pathlib
import subprocess as sp
import urllib.request
import xml.etree.ElementTree as ET
from typing import List

import tomllib
import typer
import yaml
from packaging.version import Version as Semver
from typing_extensions import Annotated

METAINFO = "org.jousse.vincent.Pomodorolm.metainfo.xml"
PACKAGE_JSON = "package.json"
PACKAGE_LOCK_JSON = "package-lock.json"
SNAPCRAFT = "snapcraft.yaml"
TAURI_CONF = "src-tauri/tauri.conf.json"
CARGO_TOML = "src-tauri/Cargo.toml"
AUR_PKGBUILD = "aur/PKGBUILD"

metainfo_first_version = Semver("0.1.8")

app = typer.Typer()


@dataclasses.dataclass
class Version:
    source: str
    number: str


@dataclasses.dataclass
class VersionState:
    aur_sha256: str = None
    aur_source: str = None

    versions: List[Version] = dataclasses.field(default_factory=list)

    def get_version_for_source(self, source: str) -> Version | None:
        return next(
            (version for version in self.versions if version.source == source), None
        )


class DataclassJSONEncoder(json.JSONEncoder):
    def default(self, o):
        if dataclasses.is_dataclass(o):
            return dataclasses.asdict(o)
        return super().default(o)


def get_version_state() -> VersionState:
    state = VersionState()

    with open(TAURI_CONF, "r") as tauri_file:
        tauri_json = json.load(tauri_file)
        tauri_version = tauri_json["version"]

        state.versions.append(Version(source=TAURI_CONF, number=tauri_version))

    with open(CARGO_TOML, "rb") as f:
        cargo_toml = tomllib.load(f)
        cargo_version = cargo_toml["package"]["version"]
        state.versions.append(Version(source=CARGO_TOML, number=cargo_version))

    with open(SNAPCRAFT, "r") as snapcraft_file:
        snapcraft_yaml = yaml.safe_load(snapcraft_file)
        snapcraft_version = snapcraft_yaml["version"]
        state.versions.append(Version(source=SNAPCRAFT, number=snapcraft_version))

    with open(PACKAGE_JSON, "r") as package_json_file:
        package_json = json.load(package_json_file)
        package_version = package_json["version"]
        state.versions.append(Version(source=PACKAGE_JSON, number=package_version))

    with open(PACKAGE_LOCK_JSON, "r") as package_lock_json_file:
        package_lock_json = json.load(package_lock_json_file)
        package_lock_version = package_lock_json["version"]
        state.versions.append(
            Version(source=PACKAGE_LOCK_JSON, number=package_lock_version)
        )

    with open(AUR_PKGBUILD, "r") as aur_pkgbuild_file:
        for line in aur_pkgbuild_file.readlines():
            if line.startswith("pkgver="):
                aur_version = line.split("=")[1].strip()

            if line.startswith("source="):
                aur_source = line.split('"')[1].strip()

            if line.startswith("sha256sums="):
                aur_sha256 = line.split("'")[1].strip()

        state.versions.append(Version(source=AUR_PKGBUILD, number=aur_version))
        state.aur_sha256 = aur_sha256
        state.aur_source = aur_source

    tree = ET.parse(METAINFO)
    root = tree.getroot()

    latest_metainfo_version = root.find("releases").find("release").attrib["version"]

    state.versions.append(Version(source=METAINFO, number=latest_metainfo_version))

    return state


@app.command()
def check_versions(
    version: Annotated[
        str, typer.Option(help="The version number that you want to check.")
    ] = None,
):
    version_state: VersionState = get_version_state()

    metainfo_releases = {}

    tree = ET.parse(METAINFO)
    root = tree.getroot()

    for release in root.find("releases"):
        metainfo_releases[release.attrib["version"]] = release.attrib["date"]

    git_cliff_output = json.loads(sp.getoutput("git-cliff --bump --context"))

    latest_git_cliff_version = None

    for release in git_cliff_output:
        date = datetime.datetime.fromtimestamp(release["timestamp"]).strftime(
            "%Y-%m-%d"
        )
        released_version = release["version"]
        stripped_version = released_version.replace("app-v", "")

        if latest_git_cliff_version is None:
            latest_git_cliff_version = stripped_version

        if (
            Semver(stripped_version) >= metainfo_first_version
            and stripped_version not in metainfo_releases
        ):
            print(f"--> ⚠️ Version {stripped_version} is missing in metainfo.xml")

    if version:
        version_to_check = version
    else:
        version_to_check = version_state.get_version_for_source(TAURI_CONF).number
        print(
            f"--> ℹ️ No version specified in parameters, reading version from `src-tauri/tauri.conf.json`: {version_to_check}"
        )

    all_versions_are_the_same = all(
        version.number == version_to_check for version in version_state.versions
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

            for version in version_state.versions:
                if version.number != version_to_check:
                    print(json.dumps(version, cls=DataclassJSONEncoder, indent=2))

        exit(1)


@app.command()
def update_aur_checksum():
    version_state: VersionState = get_version_state()

    aur_version = version_state.get_version_for_source(AUR_PKGBUILD).number

    print(f"--> Updating AUR checksum {version_state.aur_source}")
    url = version_state.aur_source.replace("${pkgver}", aur_version).replace(
        "$pkgver", aur_version
    )
    print(f"--> Downloading {url}")
    tmp_file = "pomodorolm.deb"

    urllib.request.urlretrieve(url, tmp_file)
    sha256 = ""
    with open(tmp_file, "rb", buffering=0) as f:
        sha256 = hashlib.file_digest(f, "sha256").hexdigest()

    print(f"--> SHA256: {sha256}")
    if sha256 != version_state.aur_sha256:
        print(
            f"--> Sha sums are different. Computed : {sha256}, in PKGBUILD: {version_state.aur_sha256}, updating."
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


if __name__ == "__main__":
    app()
