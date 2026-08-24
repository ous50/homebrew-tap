#!/usr/bin/env python3
"""Generate the package tables in README.md from the local tap files."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
BREW = os.environ.get("HOMEBREW_BREW") or shutil.which("brew") or "brew"


def ruby_value(text: str, key: str) -> str:
    match = re.search(rf'^\s*{key}\s+"([^"]+)"', text, re.MULTILINE)
    return match.group(1) if match else ""


def english_description(text: str) -> str:
    match = re.search(
        r'language\s+"en",\s*default:\s*true\s+do(?P<body>.*?)^\s*end',
        text,
        re.MULTILINE | re.DOTALL,
    )
    body = match.group("body") if match else text
    return ruby_value(body, "desc")


def platforms(text: str, kind: str) -> str:
    if kind != "Casks":
        return ""
    supported = []
    if re.search(r"\bos macos:", text) or re.search(r"\bon_macos\s+do", text):
        supported.append("macOS")
    if re.search(r"\bos linux:", text) or re.search(r"\bon_linux\s+do", text):
        supported.append("Linux")
    return ", ".join(supported)


def tap_token() -> str:
    """Infer the tap token (e.g. ous50/tap) from the git remote."""
    result = subprocess.run(
        ["git", "remote", "get-url", "origin"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        url = result.stdout.strip()
        match = re.search(r"[:/](?P<user>[^/]+)/homebrew-(?P<tap>[^/]+?)(?:\.git)?$", url)
        if match:
            return f"{match.group('user')}/{match.group('tap')}"
    return "ous50/tap"


TAP = tap_token()


def brew_metadata(kind: str, path: Path) -> dict:
    option = "--cask" if kind == "Casks" else "--formula"
    token = f"{TAP}/{path.stem}"
    result = subprocess.run(
        [BREW, "info", "--json=v2", option, token],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"brew info failed for {token} ({kind}):\n"
            f"stdout: {result.stdout}\n"
            f"stderr: {result.stderr}"
        )
    items = json.loads(result.stdout).get("casks" if kind == "Casks" else "formulae", [])
    if len(items) != 1:
        raise RuntimeError(f"Expected one package for {token}, got {len(items)}")
    return items[0]


def package_rows(kind: str) -> list[str]:
    directory = ROOT / kind
    if not directory.exists():
        return []
    rows = []
    for path in sorted(directory.glob("*.rb")):
        text = path.read_text(encoding="utf-8")
        metadata = brew_metadata(kind, path)
        token = metadata.get("token") or metadata.get("name") or path.stem
        if isinstance(token, list):
            token = token[0]
        version = metadata.get("version") or ruby_value(text, "version")
        description = english_description(text) or metadata.get("desc", "")
        homepage = metadata.get("homepage") or ruby_value(text, "homepage")
        license_name = metadata.get("license") or ruby_value(text, "license")
        cells = [
            f"[`{token}`]({kind}/{path.name})",
            f"`{version}`",
            description.replace("|", "\\|").replace("\n", " "),
        ]
        if kind == "Casks":
            cells.append(platforms(text, kind))
        else:
            cells.append(license_name)
        cells.append(f"[Homepage]({homepage})" if homepage else "")
        rows.append("| " + " | ".join(cells) + " |")
    return rows


def table(kind: str) -> str:
    if kind == "CASKS":
        header = "| Cask | Version | Description | Platforms | Homepage |\n| --- | --- | --- | --- | --- |"
        rows = package_rows("Casks")
    else:
        header = "| Formula | Version | Description | License | Homepage |\n| --- | --- | --- | --- | --- |"
        rows = package_rows("Formula")
    return header + ("\n" + "\n".join(rows) if rows else "")


def main() -> None:
    content = README.read_text(encoding="utf-8")
    for kind in ("CASKS", "FORMULAE"):
        pattern = re.compile(
            rf"<!-- BEGIN GENERATED {kind} -->.*?<!-- END GENERATED {kind} -->",
            re.DOTALL,
        )
        replacement = f"<!-- BEGIN GENERATED {kind} -->\n{table(kind)}\n<!-- END GENERATED {kind} -->"
        content, count = pattern.subn(replacement, content, count=1)
        if count != 1:
            raise RuntimeError(f"Missing README markers for {kind}")
    README.write_text(content.rstrip() + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
