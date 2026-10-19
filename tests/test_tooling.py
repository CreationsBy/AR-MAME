import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / (name + ".py"))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

class ToolingTests(unittest.TestCase):
    def testCatalogPreservesBiosParentAndDeviceRequirements(self):
        xml = '''<mame><game name="clone" cloneof="parent" romof="bios"><description>Clone</description>
        <year>1980</year><manufacturer>Example</manufacturer><device_ref name="device"/>
        <disk name="disc"/></game></mame>'''
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "test.xml"; path.write_text(xml)
            records = module("generate_catalog").records_from_xml(path)
        self.assertEqual(records[0]["dependencies"], ["bios", "device", "parent"])
        self.assertEqual(records[0]["disks"], ["disc"])

    def testIpaContainsPayloadAndExecutableMode(self):
        with tempfile.TemporaryDirectory() as folder:
            app = Path(folder) / "ARMAME.app"; app.mkdir()
            (app / "Info.plist").write_text("fixture")
            (app / "ARMAME").write_bytes(b"fixture executable")
            output = Path(folder) / "test.ipa"
            module("package_ipa").package(app, output)
            with zipfile.ZipFile(output) as archive:
                info = archive.getinfo("Payload/ARMAME.app/ARMAME")
                self.assertEqual((info.external_attr >> 16) & 0o777, 0o755)

    def testPackagingRefusesUnbuiltApp(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ValueError):
                module("package_ipa").package(folder, Path(folder) / "bad.ipa")

if __name__ == "__main__":
    unittest.main()
