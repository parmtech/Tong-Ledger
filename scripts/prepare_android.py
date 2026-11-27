#!/usr/bin/env python3
"""Apply Android backup exclusions to Flutter's generated platform project.

Tong Ledger uses device-protected keys that are NOT portable through Android
Auto Backup or device transfer. Restoring an encrypted file without its key can
leave user data unreadable. Generated Android projects MUST run this script
after 'flutter create' and before building until Android sources are pinned.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

ANDROID = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ANDROID)

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
XML_DIR = ROOT / "android/app/src/main/res/xml"

BACKUP_EXCLUSIONS = """<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="root" path="." />
    <exclude domain="file" path="." />
    <exclude domain="database" path="." />
    <exclude domain="sharedpref" path="." />
</full-backup-content>
"""
DATA_EXTRACTION_EXCLUSIONS = """<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
    </cloud-backup>
    <device-transfer>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
    </device-transfer>
</data-extraction-rules>
"""


def main() -> None:
    if not MANIFEST.is_file():
        raise SystemExit("Missing AndroidManifest.xml. Run flutter create first.")
    tree = ET.parse(MANIFEST)
    application = tree.getroot().find("application")
    if application is None:
        raise SystemExit("Missing <application> in Flutter's Android manifest.")

    application.set(f"{{{ANDROID}}}allowBackup", "false")
    application.set(f"{{{ANDROID}}}fullBackupContent", "@xml/tong_ledger_no_backup")
    application.set(
        f"{{{ANDROID}}}dataExtractionRules", "@xml/tong_ledger_data_extraction"
    )
    XML_DIR.mkdir(parents=True, exist_ok=True)
    (XML_DIR / "tong_ledger_no_backup.xml").write_text(
        BACKUP_EXCLUSIONS, encoding="utf-8"
    )
    (XML_DIR / "tong_ledger_data_extraction.xml").write_text(
        DATA_EXTRACTION_EXCLUSIONS, encoding="utf-8"
    )
    tree.write(MANIFEST, encoding="utf-8", xml_declaration=True)

    check = ET.parse(MANIFEST).getroot().find("application")
    if check is None or check.get(f"{{{ANDROID}}}allowBackup") != "false":
        raise SystemExit("Failed to enforce android:allowBackup=false.")
    print("Android local-vault backup and device-transfer exclusions configured.")


if __name__ == "__main__":
    main()
