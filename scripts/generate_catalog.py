"""Build frontend dependency metadata from the locked core's own DAT, not guesses."""
import json
from pathlib import Path
import shutil
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def records_from_xml(path):
    records = []
    for _, node in ET.iterparse(path, events=("end",)):
        if node.tag not in ("game", "machine"):
            continue
        dependencies = {node.get("romof", ""), node.get("cloneof", "")}
        dependencies.update(ref.get("name", "") for ref in node.findall("device_ref"))
        dependencies.discard("")
        dependencies.discard(node.get("name"))
        records.append({
            "name": node.get("name", ""), "title": node.findtext("description", ""),
            "year": node.findtext("year", ""), "manufacturer": node.findtext("manufacturer", ""),
            "parent": node.get("cloneof", ""), "dependencies": sorted(dependencies),
            "disks": sorted({disk.get("name") for disk in node.findall("disk") if disk.get("name")}),
        })
        node.clear()
    return records

def main():
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "vendor/mame2003-plus/metadata/mame2003-plus.xml"
    records = records_from_xml(source)
    if len(records) < 1000 or not any(r["name"] == "pacman" for r in records):
        raise RuntimeError("Missing or incompatible upstream DAT")
    records.append({"name": "armtest", "title": "AR-MAME Original Z80 Diagnostic", "year": "2026",
                    "manufacturer": "AR-MAME", "parent": "", "dependencies": [], "disks": []})
    resources = ROOT / "ios/Resources"
    resources.mkdir(parents=True, exist_ok=True)
    (resources / "machines.json").write_text(json.dumps(records, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    core = ROOT / "vendor/mame2003-plus"
    for path in core.iterdir():
        if path.is_file() and ("license" in path.name.lower() or "copying" in path.name.lower()):
            shutil.copy2(path, resources / ("core-" + path.name))
    print(f"Generated {len(records)} machine records")

if __name__ == "__main__":
    main()
