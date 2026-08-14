#!/usr/bin/env python3
"""Download Chrome extensions as CRX and install into Brave profile."""

from __future__ import annotations

import json
import shutil
import struct
import sys
import tempfile
import time
import urllib.request
import zipfile
from pathlib import Path

DEFAULT_PROFILE = Path.home() / "Library/Application Support/BraveSoftware/Brave-Browser/Default"
UPDATE_URL = (
    "https://clients2.google.com/service/update2/crx"
    "?response=redirect&prodversion=131.0&acceptformat=crx2,crx3&x=id%3D{id}%26uc"
)


def download_crx(ext_id: str, crx_dir: Path | None = None) -> bytes:
    cached = crx_dir / f"{ext_id}.crx" if crx_dir else None
    if cached and cached.exists():
        return cached.read_bytes()
    req = urllib.request.Request(
        UPDATE_URL.format(id=ext_id),
        headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"},
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    if cached:
        cached.parent.mkdir(parents=True, exist_ok=True)
        cached.write_bytes(data)
    return data


def crx_to_zip(data: bytes) -> bytes:
    if data[:4] != b"Cr24":
        return data
    _version, header_size = struct.unpack("<II", data[4:12])
    return data[12 + header_size :]


def install_extension(ext_id: str, name: str, brave_profile: Path, crx_dir: Path | None) -> str:
    data = download_crx(ext_id, crx_dir)
    zip_bytes = crx_to_zip(data)
    with tempfile.TemporaryDirectory() as tmp:
        zpath = Path(tmp) / "ext.zip"
        zpath.write_bytes(zip_bytes)
        extract_dir = Path(tmp) / "unpacked"
        with zipfile.ZipFile(zpath) as zf:
            zf.extractall(extract_dir)
        manifest = json.loads((extract_dir / "manifest.json").read_text())
        version = manifest.get("version", "0.0.0")
        target = brave_profile / "Extensions" / ext_id / version
        if target.exists():
            shutil.rmtree(target)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(extract_dir, target)
    return version


def register_in_preferences(ext_id: str, version: str, manifest: dict, brave_profile: Path) -> None:
    prefs_path = brave_profile / "Preferences"
    prefs = json.loads(prefs_path.read_text()) if prefs_path.exists() else {}
    ext_settings = prefs.setdefault("extensions", {}).setdefault("settings", {})
    now = str(int(time.time() * 1_000_000))
    ext_settings[ext_id] = {
        "account_extension_type": 0,
        "active_permissions": {
            "api": manifest.get("permissions", []),
            "explicit_host": manifest.get("host_permissions", manifest.get("optional_host_permissions", [])),
        },
        "creation_flags": 1,
        "from_webstore": True,
        "granted_permissions": {
            "api": manifest.get("permissions", []),
            "explicit_host": manifest.get("host_permissions", []),
        },
        "install_time": now,
        "location": 1,
        "manifest": manifest,
        "path": str(brave_profile / "Extensions" / ext_id / version),
        "state": 1,
        "was_installed_by_default": False,
        "was_installed_by_oem": False,
        "disable_reasons": 0,
        "incognito": manifest.get("incognito", "spanning"),
        "version": version,
    }
    prefs_path.write_text(json.dumps(prefs))


def main() -> int:
    ext_list = json.loads(Path(sys.argv[1]).read_text())
    brave_profile = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_PROFILE
    crx_dir = Path(sys.argv[3]) if len(sys.argv) > 3 else None
    ok, fail = [], []
    for item in ext_list:
        ext_id = item["chrome_id"]
        name = item["name"]
        existing = list((brave_profile / "Extensions" / ext_id).glob("*/manifest.json")) if (brave_profile / "Extensions" / ext_id).exists() else []
        if existing:
            version = existing[0].parent.name
            manifest = json.loads(existing[0].read_text())
            register_in_preferences(ext_id, version, manifest, brave_profile)
            ok.append(f"  ✓ {name} ({ext_id}) v{version} [already installed]")
            continue
        try:
            version = install_extension(ext_id, name, brave_profile, crx_dir)
            manifest = json.loads(
                (brave_profile / "Extensions" / ext_id / version / "manifest.json").read_text()
            )
            register_in_preferences(ext_id, version, manifest, brave_profile)
            ok.append(f"  ✓ {name} ({ext_id}) v{version}")
        except Exception as exc:
            fail.append(f"  ✗ {name} ({ext_id}): {exc}")
    print("\n".join(ok))
    if fail:
        print("\nFailed:")
        print("\n".join(fail))
    print(f"\nInstalled {len(ok)}/{len(ext_list)}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
