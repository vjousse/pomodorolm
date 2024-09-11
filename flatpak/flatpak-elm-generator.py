#!/usr/bin/env python3

import argparse
import hashlib
import json
from pathlib import Path
from urllib.request import urlretrieve

parser = argparse.ArgumentParser()

parser.add_argument("elm_json")

parser.add_argument("output_file")

args = parser.parse_args()

elm_json_file = Path(args.elm_json)

if not elm_json_file.exists():
    print(
        f"Unable to load `elm.json` file at path `{args.elm_json}`: file doesn't exit."
    )
    raise SystemExit(1)

sources = []

with open(args.elm_json, "r") as file:
    elm_json_content = json.load(file)
    dependencies = elm_json_content.get("dependencies", {})
    direct_dependencies = dependencies.get("direct", {})
    indirect_dependencies = dependencies.get("indirect", {})
    dependencies = direct_dependencies | indirect_dependencies

    for package_name in dependencies.keys():
        version_number = dependencies[package_name]
        archive_name = f"{version_number}.tar.gz"
        github_url = f"https://github.com/{package_name}/archive/{archive_name}"

        source = {
            "type": "archive",
            "archive-type": "tar-gzip",
            "url": github_url,
            "dest": f"elm-stuff/home/.elm/0.19.1/packages/{package_name}/{version_number}/",
            "strip-components": 1,
        }

        print(f"-> Downloading `{github_url}")

        urlretrieve(github_url, archive_name)

        with open(archive_name, "rb", buffering=0) as f:
            print("-> Computing sha512 of downloaded file")
            hash = hashlib.file_digest(f, "sha512").hexdigest()
            source["sha512"] = hash

        print("-> Deleting downloaded file")
        Path.unlink(archive_name)

        sources.append(source)

with open(args.output_file, "w") as output_file:
    json.dump(sources, output_file, indent=4)

    print(f"-> {len(sources)} sources written to `{args.output_file}`")
