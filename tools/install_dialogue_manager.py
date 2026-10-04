"""Vendor pinned Dialogue Manager with the documented resource-cycle compatibility fix."""
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "v4.1.0"
ARCHIVE_SHA256 = "48cdc626e01a91dce21bfc905900edf634ba3b93d979663565bbb4388d5afd1a"
URL = f"https://codeload.github.com/nathanhoad/godot_dialogue_manager/zip/refs/tags/{VERSION}"
target = ROOT / "addons/dialogue_manager"
if (target / "UPSTREAM.json").exists():
    raise SystemExit("Addon already exists; refusing to overwrite it.")
with urllib.request.urlopen(URL, timeout=90) as response:
    data = response.read()
if hashlib.sha256(data).hexdigest() != ARCHIVE_SHA256:
    raise SystemExit("Pinned archive checksum mismatch.")
with zipfile.ZipFile(io.BytesIO(data)) as archive:
    prefix = archive.namelist()[0].split("/")[0] + "/"
    for entry in archive.infolist():
        relative = entry.filename.removeprefix(prefix)
        if entry.is_dir() or not relative.startswith("addons/dialogue_manager/"):
            continue
        destination = ROOT / relative
        contents = archive.read(entry)
        if relative == "addons/dialogue_manager/dialogue_manager.gd":
            original = b"var data: Dictionary = resource.lines.get(key)\n"
            assert contents.count(original) == 1, "Upstream compatibility patch no longer matches"
            contents = contents.replace(original, b"var data: Dictionary = resource.lines.get(key).duplicate(true)\n")
        if destination.exists() and destination.read_bytes() != contents:
            raise SystemExit(f"Refusing to overwrite modified source: {destination}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(contents)
(target / "PATCHES.md").write_text(
    "# Local compatibility patch (v4.1.0)\n\n"
    "`get_line` duplicates the compiled line dictionary before adding runtime fields.\n"
    "This prevents `data.resource = resource` from creating a resource self-reference\n"
    "cycle and keeps imported source dictionaries immutable. Public API is unchanged.\n"
    "Re-check this one-line patch against upstream before upgrading.\n", encoding="utf-8")
(target / "UPSTREAM.json").write_text(json.dumps({
    "repository": "https://github.com/nathanhoad/godot_dialogue_manager",
    "version": VERSION, "archive": URL,
    "archive_sha256": hashlib.sha256(data).hexdigest(), "license": "MIT",
    "patches": ["PATCHES.md: isolate runtime line dictionaries"],
}, indent=2) + "\n", encoding="utf-8")
print(f"Installed Dialogue Manager {VERSION}: {target}")
