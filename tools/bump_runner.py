#!/usr/bin/env python3
"""Pin docker-bake.hcl to an actions/runner release, with the checksums of its Linux tarballs.

Renovate picks the version and runs this as a post-upgrade task; the checksums come from
the release notes because the release attaches no checksum file.
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path

RELEASE_URL = "https://api.github.com/repos/actions/runner/releases/tags/v{version}"
BAKE_FILE = Path(__file__).resolve().parent.parent / "docker-bake.hcl"
# bake variable per checksum, keyed by the tarball architecture the release notes use
CHECKSUM_VARIABLES = {"linux-x64": "GH_RUNNER_CHECKSUM_X64", "linux-arm64": "GH_RUNNER_CHECKSUM_ARM64"}

VERSION = re.compile(r"^\d+\.\d+\.\d+$")
TAG = re.compile(r"^v(\d+\.\d+\.\d+)$")
# the release notes carry every tarball's SHA-256 between these markers
CHECKSUM = re.compile(r"<!-- BEGIN SHA (?P<arch>[a-z0-9-]+) -->(?P<sha>[0-9a-f]{64})<!-- END SHA (?P=arch) -->")

USAGE = "usage: bump_runner.py VERSION [BAKE_FILE]"


class ApiError(Exception):
    pass


class BakeError(Exception):
    pass


@dataclass(frozen=True)
class Release:
    version: str
    checksums: Mapping[str, str]

    @classmethod
    def from_api(cls, payload: Mapping) -> Release:
        tag = payload.get("tag_name", "")
        match = TAG.match(tag)
        if not match:
            raise ApiError(f"unexpected release tag {tag!r}")
        found = {match["arch"]: match["sha"] for match in CHECKSUM.finditer(payload.get("body") or "")}
        missing = [arch for arch in CHECKSUM_VARIABLES if arch not in found]
        if missing:
            raise ApiError(f"release {tag} notes carry no checksum for: {' '.join(missing)}")
        return cls(match.group(1), {arch: found[arch] for arch in CHECKSUM_VARIABLES})

    def bake_variables(self) -> dict[str, str]:
        variables = {"GH_RUNNER_VERSION": self.version}
        for arch, name in CHECKSUM_VARIABLES.items():
            variables[name] = f"sha256:{self.checksums[arch]}"
        return variables


def fetch_release(version: str, token: str | None = None) -> Release:
    url = RELEASE_URL.format(version=version)
    headers = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            release = Release.from_api(json.load(response))
    except urllib.error.HTTPError as error:
        body = error.read().decode(errors="replace").strip()
        raise ApiError(f"GET {url} returned HTTP {error.code}: {body}") from error
    except urllib.error.URLError as error:
        raise ApiError(f"GET {url} failed: {error.reason}") from error
    if release.version != version:
        raise ApiError(f"GET {url} returned release {release.version}")
    return release


def _default_pattern(name: str) -> re.Pattern:
    return re.compile(rf'^(variable\s+"{re.escape(name)}"\s*\{{\s*default\s*=\s*")([^"]*)(")', re.MULTILINE)


def read_variable(text: str, name: str) -> str:
    matches = _default_pattern(name).findall(text)
    if len(matches) != 1:
        raise BakeError(f"expected exactly one variable {name!r} with a default, found {len(matches)}")
    return matches[0][1]


def set_variable(text: str, name: str, value: str) -> str:
    read_variable(text, name)
    return _default_pattern(name).sub(lambda match: f"{match.group(1)}{value}{match.group(3)}", text)


def pin(bake_file: Path, release: Release) -> None:
    text = bake_file.read_text()
    for name, value in release.bake_variables().items():
        text = set_variable(text, name, value)
    bake_file.write_text(text)


def main(argv: Sequence[str]) -> int:
    if not 1 <= len(argv) <= 2 or not VERSION.match(argv[0]):
        print(USAGE, file=sys.stderr)
        return 2
    version = argv[0]
    bake_file = Path(argv[1]) if len(argv) == 2 else BAKE_FILE
    try:
        release = fetch_release(version, os.environ.get("GITHUB_TOKEN"))
        pin(bake_file, release)
    except (ApiError, BakeError, OSError) as error:
        print(error, file=sys.stderr)
        return 1
    print(f"{bake_file.name}: pinned runner {release.version} and its checksums", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
