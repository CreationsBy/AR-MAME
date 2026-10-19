"""Fetch the locked core and inject our read-only machine/graphics adapter."""
import json
from pathlib import Path
import shutil
import subprocess
from make_diagnostic import driver_source, write_container

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "vendor" / "mame2003-plus"

def main():
    lock = json.loads((ROOT / "mame/core.lock.json").read_text())
    if not (CORE / ".git").exists():
        CORE.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "init", str(CORE)], check=True)
        subprocess.run(["git", "-C", str(CORE), "remote", "add", "origin", lock["repository"]], check=True)
    subprocess.run(["git", "-C", str(CORE), "fetch", "--depth", "1", "origin", lock["revision"]], check=True)
    subprocess.run(["git", "-C", str(CORE), "checkout", "--detach", "FETCH_HEAD"], check=True)
    actual = subprocess.check_output(["git", "-C", str(CORE), "rev-parse", "HEAD"], text=True).strip()
    if actual != lock["revision"]:
        raise RuntimeError("Core revision mismatch")
    for filename in ["ARCore.c", "ARCore.h"]:
        shutil.copy2(ROOT / "mame" / filename, CORE / "src" / filename)
    # Linux validation needs our extra read-only ABI visible alongside libretro.
    exports = subprocess.check_output(["git", "-C", str(CORE), "show", "HEAD:link.T"], text=True)
    (CORE / "link.T").write_text(exports.replace("global: retro_*;", "global: retro_*; am_machine; am_visuals;"))
    # Bundled legacy zlib treats the modern TARGET_OS_MAC macro as classic Mac OS,
    # redefining fdopen before Apple's stdio declarations. Darwin has real fdopen.
    zutil = subprocess.check_output(["git", "-C", str(CORE), "show", "HEAD:src/lib/zlib/zutil.h"], text=True)
    old_guard = "#if defined(MACOS) || defined(TARGET_OS_MAC)"
    if old_guard not in zutil:
        raise RuntimeError("Upstream zlib platform guard changed; review the compatibility patch")
    (CORE / "src/lib/zlib/zutil.h").write_text(zutil.replace(old_guard, "#if defined(MACOS) || (defined(TARGET_OS_MAC) && !defined(__APPLE__))"))
    pacman = subprocess.check_output(["git", "-C", str(CORE), "show", "HEAD:src/drivers/pacman.c"], text=True)
    (CORE / "src/drivers/pacman.c").write_text(pacman + driver_source())
    driver = subprocess.check_output(["git", "-C", str(CORE), "show", "HEAD:src/driver.c"], text=True)
    marker = "DRIVER( pacman )"
    if marker not in driver:
        raise RuntimeError("Core driver registration changed")
    (CORE / "src/driver.c").write_text(driver.replace(marker, "DRIVER( armtest )\n\t" + marker))
    write_container(ROOT / "ios/Resources/armtest.zip")
    original = subprocess.check_output(["git", "-C", str(CORE), "show", "HEAD:Makefile.common"], text=True)
    (CORE / "Makefile.common").write_text(original + "\nSOURCES_C += $(CORE_DIR)/ARCore.c\n")
    original = subprocess.check_output(["git", "-C", str(CORE), "show", "HEAD:Makefile"], text=True)
    # Retain upstream compatibility sources (STATIC_LINKING=0); archive those exact objects.
    (CORE / "Makefile").write_text(original + "\narmame-static: $(OBJECTS)\n\t$(AR) rcs $(ARMAME_ARCHIVE) $(OBJECTS)\n")
    print(f"Prepared {lock['name']} at {actual}")

if __name__ == "__main__":
    main()
