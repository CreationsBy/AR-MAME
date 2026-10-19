"""Package a compiled .app for subsequent Windows signing. Does not sign anything."""
from pathlib import Path
import stat
import sys
import zipfile

def package(app, output):
    app, output = Path(app), Path(output)
    if not app.is_dir() or not (app / "Info.plist").is_file() or not (app / "ARMAME").is_file():
        raise ValueError("Expected a compiled ARMAME.app with executable and Info.plist")
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(app.rglob("*")):
            if not path.is_file():
                continue
            name = (Path("Payload") / app.name / path.relative_to(app)).as_posix()
            info = zipfile.ZipInfo.from_file(path, name)
            if path.name == "ARMAME":
                info.external_attr = (stat.S_IFREG | 0o755) << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED)
    print(f"Packaged unsigned IPA: {output}")

if __name__ == "__main__":
    package(*sys.argv[1:])
