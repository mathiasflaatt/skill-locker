#!/usr/bin/env python3
"""Lint the skills in this repo. Exit 1 on any error. Run through `skill-locker check`."""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
EXTERNAL = REPO / "external-skills.txt"  # skills that live outside the repo (plugins, built-ins, local-only)

BOLD = re.compile(r"\*\*([a-z0-9]+(?:-[a-z0-9]+)+)\*\*")  # **kebab-name** with at least one hyphen
MD_LINK = re.compile(r"\]\(([^)\s#]+)(?:#[^)]*)?\)")
LOCAL_PATH = re.compile(r"`((?:playbooks|principles|references|scripts)/[\w./-]+\.\w+)`")
FENCE = re.compile(r"^(```|~~~).*?^\1", re.S | re.M)
HOME_SKILL = re.compile(r"~/\.(?:agents|claude)/skills/([\w-]+)(/[\w./-]*)?")


def skill_dirs():
    for d in sorted((REPO / "shared").iterdir()):
        if d.is_dir():
            yield d
    for d in sorted((REPO / "machines").glob("*/*")):
        if d.is_dir():
            yield d


def frontmatter(text):
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    fields = {}
    for line in m.group(1).splitlines():
        k, sep, v = line.partition(":")
        if sep and not line.startswith(" "):
            fields[k.strip()] = v.strip()
    return fields


def known_names():
    names = {d.name for d in skill_dirs() if (d / "SKILL.md").exists()}
    names |= {d.name for d in (REPO / "extras/.agents/agent-skills").glob("*/*") if d.is_dir()}
    names |= {p.stem for p in (REPO / "shared/mathito-mode/principles").glob("*.md")}  # pstack principle names
    if EXTERNAL.exists():
        names |= {l.split("#")[0].strip() for l in EXTERNAL.read_text().splitlines()} - {""}
    return names


def check(errors):
    names = known_names()
    credits = (REPO / "CREDITS.md").read_text()
    repo_skill_paths = {d.name: d for d in skill_dirs()}

    for d in skill_dirs():
        rel = d.relative_to(REPO)
        skill_md = d / "SKILL.md"
        if not skill_md.exists():
            errors.append(f"{rel}: no SKILL.md")
            continue
        fm = frontmatter(skill_md.read_text())
        if fm is None:
            errors.append(f"{rel}/SKILL.md: no frontmatter")
        else:
            if fm.get("name") != d.name:
                errors.append(f"{rel}/SKILL.md: name '{fm.get('name')}' does not match folder '{d.name}'")
            if not fm.get("description"):
                errors.append(f"{rel}/SKILL.md: empty description")

        if rel.parts[0] == "shared":
            if f"`{d.name}`" not in credits and f"shared/{d.name}/" not in credits:
                errors.append(f"{rel}: no row in CREDITS.md")
            elif f"`{d.name}`" in credits.split("## My own work")[0] and not list(d.glob("LICENSE*")):
                errors.append(f"{rel}: credited to another author but has no LICENSE file")

    md_files = [p for d in skill_dirs() for p in d.rglob("*.md")]
    md_files += list((REPO / "extras").rglob("*.md"))
    for md in md_files:
        if "node_modules" in md.parts:
            continue
        rel = md.relative_to(REPO)
        text = FENCE.sub("", md.read_text())  # examples in code fences are not real links
        for name in sorted(set(BOLD.findall(text))):
            if name not in names:
                errors.append(f"{rel}: **{name}** is not a skill in the repo or external-skills.txt")
        for target in MD_LINK.findall(text):
            if re.match(r"[a-z]+:", target) or target.startswith(("<", "/")) or not re.search(r"[./]", target):
                continue
            if not (md.parent / target).exists():
                errors.append(f"{rel}: link '{target}' does not resolve")
        skill_root = next((p for p in [md.parent, *md.parents] if (p / "SKILL.md").exists()), None)
        for target in LOCAL_PATH.findall(text) if skill_root else []:
            if not (skill_root / target).exists() and not (md.parent / target).exists():
                errors.append(f"{rel}: path '{target}' does not resolve")
        for name, sub in HOME_SKILL.findall(text):
            if name not in repo_skill_paths:
                if name not in names:
                    errors.append(f"{rel}: '~/.agents/skills/{name}' is not a skill in the repo or external-skills.txt")
                continue
            if sub and "<" not in sub and not (repo_skill_paths[name] / sub.lstrip("/")).exists():
                errors.append(f"{rel}: '~/.agents/skills/{name}{sub}' does not resolve")


def main():
    errors = []
    check(errors)
    for e in errors:
        print(f"error: {e}")
    print(f"{len(errors)} error(s)" if errors else "check passed")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
