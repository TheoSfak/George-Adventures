#!/usr/bin/env python3
"""Makes a release in one command (run only when Theodore asks for a release).

    python tools/release.py 1.0.0            # export, zip, checksum, GitHub release
    python tools/release.py 1.0.0 --dry-run  # everything except the upload (git checks only warn)

Needs: godot and gh on the PATH, the export templates installed, `export_presets.cfg` (committed).
The release notes are docs/release-notes/<version>.md when it exists (short, Greek: the game's update card
shows the first 4 lines), otherwise the CHANGELOG.md section whose heading starts with "## <version>".
The updater (scripts/update_logic.gd) expects exactly these asset names:
    George-Adventures-<version>-win64.zip  and  George-Adventures-<version>-win64.zip.sha256
"""
import argparse
import hashlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"
EXE = "GeorgeAdventures.exe"


def run(cmd, **kw):
    print("+", " ".join(str(c) for c in cmd))
    return subprocess.run(cmd, check=True, cwd=ROOT, **kw)


def out(cmd):
    return subprocess.run(cmd, check=True, cwd=ROOT, capture_output=True, text=True).stdout.strip()


def project_version():
    text = (ROOT / "project.godot").read_text(encoding="utf-8")
    m = re.search(r'^config/version="([^"]+)"', text, re.M)
    return m.group(1) if m else ""


def changelog_section(version):
    lines = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8").splitlines()
    head = re.compile(r"^##\s+v?" + re.escape(version) + r"(\s|$)")
    start = next((i for i, l in enumerate(lines) if head.match(l)), None)
    if start is None:
        return ""
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    return "\n".join(lines[start + 1:end]).strip() + "\n"


def problem(message, dry_run, problems):
    problems.append(message)
    print(("WARN  " if dry_run else "ERROR ") + message)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("version")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    version = args.version.lstrip("v")
    problems = []

    if out(["git", "branch", "--show-current"]) != "main":
        problem("not on the main branch", args.dry_run, problems)
    if out(["git", "status", "--porcelain"]):
        problem("the working tree is not clean", args.dry_run, problems)
    if project_version() != version:
        problem("config/version in project.godot is %r, not %r" % (project_version(), version), args.dry_run, problems)
    notes = changelog_section(version)
    if not notes:
        problem("CHANGELOG.md has no '## %s' section" % version, args.dry_run, problems)
    # The notes are shown in the game's update card, so a short Greek text is preferred:
    # docs/release-notes/<version>.md (3 to 4 short lines) replaces the CHANGELOG section as the release body.
    notes_file = ROOT / "docs" / "release-notes" / (version + ".md")
    if notes_file.exists():
        notes = notes_file.read_text(encoding="utf-8")
    else:
        print("WARN  no docs/release-notes/%s.md: the long CHANGELOG section becomes the release body "
              "(the game's update card only shows its first 4 lines)" % version)
    if problems and not args.dry_run:
        sys.exit(1)

    BUILD.mkdir(exist_ok=True)
    run(["godot", "--path", ".", "--headless", "--export-release", "Windows Desktop", str(BUILD / EXE)])
    zip_path = BUILD / ("George-Adventures-%s-win64.zip" % version)
    if zip_path.exists():
        zip_path.unlink()
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(BUILD / EXE, EXE)
        for bat in sorted((ROOT / "tools" / "launchers").glob("*.bat")):
            z.write(bat, bat.name)
        # instructions for the player (README.txt) and the legal notices that must travel with the exe
        for extra in [ROOT / "tools" / "launchers" / "README.txt", ROOT / "LICENSE", ROOT / "THIRD_PARTY_NOTICES.md"]:
            z.write(extra, extra.name)
    digest = hashlib.sha256(zip_path.read_bytes()).hexdigest()
    sha_path = Path(str(zip_path) + ".sha256")
    sha_path.write_text("%s  %s\n" % (digest, zip_path.name), encoding="utf-8")
    notes_path = BUILD / "release-notes.md"
    notes_path.write_text(notes, encoding="utf-8")
    print("zip:", zip_path, "%.1f MB" % (zip_path.stat().st_size / 1048576))
    print("sha256:", digest)
    if args.dry_run:
        print("dry run: nothing was uploaded")
        return
    run(["gh", "release", "create", "v" + version, str(zip_path), str(sha_path),
         "--title", version, "--notes-file", str(notes_path)])
    print("released v" + version)


if __name__ == "__main__":
    main()
