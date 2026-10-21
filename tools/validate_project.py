"""Static sanity checks for the IslandNeonRGB project (no Xcode available here)."""
import json
import re
import sys
import xml.dom.minidom
from pathlib import Path

root = Path(sys.argv[1])
problems = []

# --- pbxproj: every referenced 24-hex ID must be defined exactly once ---
pbx = (root / "IslandNeonRGB.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
defined = re.findall(r"^\s*([0-9A-F]{24})\s*(?:/\*.*?\*/)?\s*=\s*\{\s*isa", pbx, re.M)
referenced = set(re.findall(r"\b([0-9A-F]{24})\b", pbx))
dupes = {d for d in defined if defined.count(d) > 1}
missing = referenced - set(defined)
if dupes:
    problems.append(f"pbxproj duplicate object IDs: {sorted(dupes)}")
if missing:
    problems.append(f"pbxproj referenced but undefined IDs: {sorted(missing)}")
if pbx.count("{") != pbx.count("}"):
    problems.append("pbxproj brace mismatch")
if pbx.count("(") != pbx.count(")"):
    problems.append("pbxproj paren mismatch")
# Every object has an isa
objects = re.findall(r"^\s*[0-9A-F]{24}\s*(?:/\*.*?\*/)?\s*=\s*\{(.*?)^\s*\};", pbx, re.M | re.S)
print(f"pbxproj: {len(defined)} objects defined, {len(referenced)} IDs referenced")

# --- XML files (plists, entitlements, scheme, workspace) ---
for p in list(root.rglob("*.plist")) + list(root.rglob("*.entitlements")) + list(root.rglob("*.xcscheme")) + list(root.rglob("*.xcworkspacedata")):
    try:
        xml.dom.minidom.parse(str(p))
    except Exception as e:  # noqa: BLE001
        problems.append(f"XML parse error in {p}: {e}")

# --- JSON asset catalogs ---
for p in root.rglob("Contents.json"):
    try:
        json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        problems.append(f"JSON parse error in {p}: {e}")

# --- Swift: brace/paren/bracket balance ignoring strings and comments ---
def strip_swift(src: str) -> str:
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if c == '"':
            # string literal (handles \( ) interpolation crudely by tracking depth)
            i += 1
            depth = 0
            while i < n:
                if src[i] == "\\" and i + 1 < n:
                    if src[i + 1] == "(":
                        depth += 1
                        i += 2
                        continue
                    i += 2
                    continue
                if depth and src[i] == ")":
                    depth -= 1
                elif depth and src[i] == "(":
                    depth += 1
                elif not depth and src[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)

swift_files = sorted(root.rglob("*.swift"))
for p in swift_files:
    s = strip_swift(p.read_text(encoding="utf-8"))
    for a, b in ("{}", "()", "[]"):
        if s.count(a) != s.count(b):
            problems.append(f"{p.relative_to(root)}: unbalanced {a}{b} ({s.count(a)} vs {s.count(b)})")
print(f"swift: {len(swift_files)} files checked")

# --- Cross-file symbol sanity: every `struct/class/enum X` used as X( or X. exists ---
declared = set()
for p in swift_files:
    declared |= set(re.findall(r"\b(?:struct|class|enum|protocol)\s+([A-Z]\w*)", p.read_text(encoding="utf-8")))
project_types = {"NeonSettings", "NeonConfig", "IslandGeometry", "DevicePreset", "NeonOutlineView", "NeonIslandView",
                 "NeonIslandFrame", "ContentView", "NeonHomeView", "LabeledSlider", "ModePicker", "PhoneTopMockup",
                 "ImmersiveIslandView", "SettingsView", "LiveActivityView", "LimitationsView", "NeonActivityManager",
                 "IslandNeonLiveActivity", "LockScreenNeonView", "StaticNeonPill", "NeonDot", "NeonActivityAttributes",
                 "NeonColorMode", "HSBColor", "AppTab", "IslandNeonRGBApp", "IslandNeonWidgetBundle"}
for t in sorted(project_types - declared):
    problems.append(f"expected type not declared: {t}")

if problems:
    print("PROBLEMS:")
    for pr in problems:
        print(" -", pr)
    sys.exit(1)
print("OK: no structural problems found")
