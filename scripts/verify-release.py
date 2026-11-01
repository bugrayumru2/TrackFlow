#!/usr/bin/env python3
"""Check distribution metadata/resources without launching the app."""
from pathlib import Path
import argparse
import plistlib
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("app", type=Path)
parser.add_argument("--universal", action="store_true")
args = parser.parse_args()
contents = args.app / "Contents"
info = plistlib.loads((contents / "Info.plist").read_bytes())
assert info.get("CFBundleIdentifier") == "dev.trackflow.TrackFlow", "Incorrect app identity"
assert info.get("CFBundleShortVersionString") == "0.1.0", "Incorrect version"
assert info.get("LSMinimumSystemVersion") == "15.0", "Incorrect deployment target"
assert info.get("NSAppleEventsUsageDescription"), "Missing Automation usage description"
resources = contents / "Resources"
assert (resources / "AppIcon.icns").exists(), "Missing app icon"
for language in ["en", "tr"]:
    assert (resources / (language + ".lproj") / "Localizable.strings").exists()
    assert (resources / (language + ".lproj") / "InfoPlist.strings").exists()
for name in ["TrackFlow-MIT.txt", "OpenMultitouchSupport-MIT.txt", "SwiftAsyncAlgorithms-Apache-2.0.txt",
             "SwiftCollections-Apache-2.0.txt"]:
    assert list(resources.rglob(name)), "Missing license: " + name
architectures = subprocess.check_output(
    ["lipo", "-archs", str(contents / "MacOS/TrackFlow")], text=True).split()
assert "arm64" in architectures
if args.universal:
    assert "x86_64" in architectures
print("Release identity, version, icon, locales, licenses and architectures verified:", ", ".join(architectures))
