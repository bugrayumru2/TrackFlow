#!/usr/bin/env python3
"""Test actual app sources without starting hardware monitoring."""
from pathlib import Path
import subprocess
import sys
root = Path(__file__).resolve().parents[1]
derived = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root / ".build/DerivedData"
products = derived / "Build/Products/Debug"
if not (products / "OpenMultitouchSupport.swiftmodule").exists():
    raise SystemExit("Run ./scripts/build.sh Debug first.")
output = root / ".build/checks/workspace"
output.parent.mkdir(parents=True, exist_ok=True)
command = ["xcrun", "swiftc", "-parse-as-library", "-module-cache-path",
           str(root / ".build/module-cache"), "-I", str(products), "-F", str(products)]
command += [str(p) for p in sorted((root / "TrackFlow").glob("*.swift")) if p.name != "MyApp.swift"]
command += [str(root / "Tests/WorkspaceChecks/main.swift")]
command += [str(p) for p in sorted(products.glob("*.o"))]
command += ["-framework", "OpenMultitouchSupportXCF", "-Xlinker", "-rpath",
            "-Xlinker", str(products), "-o", str(output)]
subprocess.run(command, check=True, cwd=root)
subprocess.run([str(output)], check=True, cwd=root)
