"""Run the UI contract tests with a local Luau CLI (no Roblox rendering)."""

import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("luau", help="Path to the Luau CLI executable")
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
source = "\n".join(
    [
        (root / "tests/roblox_mock.luau").read_text(encoding="utf-8"),
        "local function loadLibrary()",
        (root / "VantaUI.lua").read_text(encoding="utf-8-sig"),
        "end\nlocal Vanta = loadLibrary()",
        (root / "tests/library.spec.luau").read_text(encoding="utf-8"),
    ]
)
with tempfile.TemporaryDirectory(prefix="vantaui-tests-") as temp:
    script = Path(temp) / "tests.luau"
    script.write_text(source, encoding="utf-8")
    result = subprocess.run([args.luau, str(script)], check=False)
    raise SystemExit(result.returncode)
