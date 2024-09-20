#!/usr/bin/env python

import argparse
import json
import xml.etree.ElementTree as ET

import yaml

METAINFO = "org.jousse.vincent.Pomodorolm.metainfo.xml"
PACKAGE_JSON = "package.json"
SNAPCRAFT = "snapcraft.yaml"
TAURI_CONF = "src-tauri/tauri.conf.json"

tauri_version = None
snapcraft_version = None
package_json_version = None
metainfo_version = None

parser = argparse.ArgumentParser(
    description="Check the coherence of files containing version information."
)
parser.add_argument("--version", help="The version you want to publish", type=str)

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

tree = ET.parse(METAINFO)
root = tree.getroot()

latest_metainfo_version = root.find("releases").find("release").attrib["version"]

versions.append({"source": "metainfo", "version": latest_metainfo_version})

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
