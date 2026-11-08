#!/usr/bin/env bash
# Fixture salt and hostnames below are fake. They are not a production salt
# and they are not a map of real machines.
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
SL="$ROOT/bin/skill-locker"
SALT='test-salt-not-production'
HOST='fixture-host'
OTHER='other-host'
ID_HOST='b38ddb3aec72'
ID_OTHER='018e904dba4f'

TMPS=()
cleanup() {
  local d
  for d in "${TMPS[@]+"${TMPS[@]}"}"; do
    rm -rf "$d"
  done
}
trap cleanup EXIT

before_status="$(git -C "$ROOT" status --porcelain)"

fail() { echo "FAIL: $*" >&2; exit 1; }

py_id() {
  python3 -c 'import hashlib,sys; print(hashlib.sha256(sys.argv[1].encode()).hexdigest()[:12])' "$1"
}

[[ "$(py_id "${SALT}${HOST}")" == "$ID_HOST" ]] || fail "fixture vector drifted"
[[ "$(py_id "${SALT}${OTHER}")" == "$ID_OTHER" ]] || fail "other vector drifted"
[[ "$(py_id "${SALT}:${HOST}")" != "$ID_HOST" ]] || fail "separator must change the id"
[[ "$(py_id "${SALT}Fixture-Host")" != "$ID_HOST" ]] || fail "hostname case must change the id"

new_repo() {
  REPO="$(mktemp -d)"
  HOME="$(mktemp -d)"
  LOCAL="$HOME/.config/skill-locker/local.env"
  TMPS+=("$REPO" "$HOME")
  mkdir -p "$(dirname "$LOCAL")" "$REPO/shared" "$REPO/machines" "$REPO/extras/.agents" "$REPO/extras/.agents/lavish"
  printf 'agents\n' > "$REPO/extras/.agents/AGENTS.md"
  printf 'lavish\n' > "$REPO/extras/.agents/lavish/GUIDE.md"
  git -C "$REPO" init -q
  git -C "$REPO" config user.email test@example.com
  git -C "$REPO" config user.name 'Skill Locker Test'
  unset SL_SALT SL_MACHINE || true
  SL_HOST="$HOST"
}

sl() {
  local -a args=(
    "PATH=$PATH"
    "HOME=$HOME"
    "SKILL_LOCKER_REPO=$REPO"
    "SKILL_LOCKER_LOCAL_ENV=$LOCAL"
    "SKILL_LOCKER_HOSTNAME=${SL_HOST:-$HOST}"
  )
  if [[ -n "${SL_SALT+x}" ]]; then
    args+=("SKILL_LOCKER_SALT=$SL_SALT")
  fi
  if [[ -n "${SL_MACHINE+x}" ]]; then
    args+=("SKILL_LOCKER_MACHINE=$SL_MACHINE")
  fi
  env -i "${args[@]}" "$SL" "$@"
}

expect_fail() {
  local out err code
  out="$(mktemp)"
  err="$(mktemp)"
  TMPS+=("$out" "$err")
  set +e
  sl "$@" >"$out" 2>"$err"
  code=$?
  set -e
  [[ "$code" -ne 0 ]] || fail "expected failure: $*"
  cat "$out"
  cat "$err" >&2
}

# --- id formula, no unsalted fallback ---
new_repo
unsalted="$(py_id "$HOST")"
set +e
out="$(sl machine-id 2>&1)"
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "machine-id without salt should fail"
[[ "$out" != *"$unsalted"* ]] || fail "unsalted hash was used"
[[ "$out" != *"$SALT"* ]] || fail "salt leaked into a failure"

printf 'SKILL_LOCKER_SALT=%s\n' "$SALT" > "$LOCAL"
chmod 600 "$LOCAL"
got="$(sl machine-id --derived)"
[[ "$got" == "$ID_HOST" ]] || fail "derived id $got != $ID_HOST"
SL_HOST="$OTHER"
[[ "$(sl machine-id --derived)" == "$ID_OTHER" ]] || fail "other host id"
SL_HOST='Fixture-Host'
[[ "$(sl machine-id --derived)" != "$ID_HOST" ]] || fail "case folded the hostname"
SL_HOST="$HOST"

# environment salt wins over the file for this process
SL_SALT='other-salt-not-production'
[[ "$(sl machine-id --derived)" != "$ID_HOST" ]] || fail "file salt beat the environment"
[[ "$(sl machine-id --derived)" == "$(py_id "${SL_SALT}${HOST}")" ]] || fail "env salt was not hashed"
unset SL_SALT

# --- setup is idempotent and does not print the salt ---
new_repo
out="$(sl setup 2>&1)"
file_salt="$(sed -n 's/^SKILL_LOCKER_SALT=//p' "$LOCAL")"
[[ "${#file_salt}" -eq 64 ]] || fail "generated salt length ${#file_salt}"
[[ "$file_salt" =~ ^[0-9a-f]+$ ]] || fail "generated salt is not hex"
[[ "$out" != *"$file_salt"* ]] || fail "setup printed the salt"
[[ "$out" != *"$HOST"* ]] || fail "setup printed the hostname"
[[ "$(grep -c '^SKILL_LOCKER_SALT=' "$LOCAL")" -eq 1 ]] || fail "salt line count"
mode="$(stat -c %a "$LOCAL")"
[[ "$mode" == "600" ]] || fail "local env mode $mode"
id_line="$(printf '%s\n' "$out" | sed -n 's/^machine id: //p')"
[[ "$id_line" =~ ^[0-9a-f]{12}$ ]] || fail "setup id $id_line"
[[ -f "$REPO/machines/$id_line/extras" ]] || fail "new machine folder missing"
[[ ! -d "$REPO/machines/$HOST" ]] || fail "setup created a hostname folder"
printf 'keep-me\n' > "$REPO/machines/$id_line/extras"
out2="$(sl setup 2>&1)"
[[ "$(sed -n 's/^SKILL_LOCKER_SALT=//p' "$LOCAL")" == "$file_salt" ]] || fail "setup rotated the salt"
[[ "$(grep -c '^SKILL_LOCKER_SALT=' "$LOCAL")" -eq 1 ]] || fail "setup duplicated the salt"
[[ "$(cat "$REPO/machines/$id_line/extras")" == "keep-me" ]] || fail "setup clobbered extras"
[[ "$out2" != *"$file_salt"* ]] || fail "second setup printed the salt"

# pre-seeded per-user salt is kept
new_repo
printf 'SKILL_LOCKER_SALT="%s"\n' "$SALT" > "$LOCAL"
out="$(sl setup 2>&1)"
[[ "$(sed -n 's/^SKILL_LOCKER_SALT=//p' "$LOCAL" | tr -d '"')" == "$SALT" ]] || fail "quoted salt was replaced"
[[ "$out" == *"machine id: $ID_HOST"* ]] || fail "setup did not print the derived id"
[[ "$out" != *"$SALT"* ]] || fail "pre-seeded salt was printed"
[[ -d "$REPO/machines/$ID_HOST" ]] || fail "derived folder was not created"

# legacy folder is left in place, and setup does not hide it
new_repo
mkdir -p "$REPO/machines/$HOST/demo"
printf 'skill-body\n' > "$REPO/machines/$HOST/demo/SKILL.md"
printf '# keep\n.agents/AGENTS.md\n\n.agents/lavish\n' > "$REPO/machines/$HOST/extras"
cp "$REPO/machines/$HOST/extras" "$HOME/extras.before"
printf 'SKILL_LOCKER_SALT=%s\n' "$SALT" > "$LOCAL"
out="$(sl setup 2>&1)"
[[ ! -d "$REPO/machines/$ID_HOST" ]] || fail "setup created a derived folder over a legacy folder"
cmp -s "$REPO/machines/$HOST/extras" "$HOME/extras.before" || fail "setup edited the legacy extras list"
[[ "$out" == *"legacy machine folder still in use"* ]] || fail "setup did not report the legacy folder"
[[ "$out" != *"$HOST"* ]] || fail "legacy setup printed the hostname"
[[ "$(sl machine-id)" == "$HOST" ]] || fail "legacy id was not the folder name"
[[ "$(sl machine-id --derived)" == "$ID_HOST" ]] || fail "derived id while legacy folder exists"

# --- migrate ---
git -C "$REPO" add machines
git -C "$REPO" commit -q -m 'fixture'
out="$(sl migrate 2>&1)"
[[ -d "$REPO/machines/$ID_HOST" ]] || fail "migrate did not create the derived folder"
[[ ! -e "$REPO/machines/$HOST" ]] || fail "legacy folder still present"
[[ "$(cat "$REPO/machines/$ID_HOST/demo/SKILL.md")" == "skill-body" ]] || fail "skill body changed"
cmp -s "$REPO/machines/$ID_HOST/extras" "$HOME/extras.before" || fail "extras changed during migrate"
[[ "$out" == *"migrated machine folder to $ID_HOST"* ]] || fail "migrate output: $out"
[[ "$out" != *"$HOST"* ]] || fail "migrate printed the legacy name"
[[ "$out" != *"$SALT"* ]] || fail "migrate printed the salt"
[[ "$(sl machine-id)" == "$ID_HOST" ]] || fail "id after migrate"
out="$(sl migrate 2>&1)"
[[ "$out" == *"already uses the derived id"* ]] || fail "second migrate: $out"
[[ -d "$REPO/machines/$ID_HOST" && ! -e "$REPO/machines/$HOST" ]] || fail "second migrate moved the folder"

# refuse without a salt, and refuse to merge both folders
new_repo
mkdir -p "$REPO/machines/$HOST"
printf 'x\n' > "$REPO/machines/$HOST/extras"
set +e
out="$(sl migrate 2>&1)"
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "migrate without salt succeeded"
[[ -d "$REPO/machines/$HOST" ]] || fail "unsalted migrate removed the folder"
[[ "$out" != *"$unsalted"* ]] || fail "unsalted migrate printed a raw hash"
[[ "$out" == *"unsalted"* ]] || fail "unsalted migrate did not say why"

printf 'SKILL_LOCKER_SALT=%s\n' "$SALT" > "$LOCAL"
mkdir -p "$REPO/machines/$ID_HOST"
set +e
out="$(sl migrate 2>&1)"
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "migrate merged two folders"
[[ -d "$REPO/machines/$HOST" && -d "$REPO/machines/$ID_HOST" ]] || fail "merge refusal removed a folder"
[[ "$out" == *"not merging"* ]] || fail "merge message: $out"

# --from hashes that name, not the current hostname
rmdir "$REPO/machines/$ID_HOST" 2>/dev/null || rm -rf "$REPO/machines/$ID_HOST"
mkdir -p "$REPO/machines/$OTHER"
printf 'other\n' > "$REPO/machines/$OTHER/extras"
out="$(sl migrate --from "$OTHER" 2>&1)"
[[ -d "$REPO/machines/$ID_OTHER" ]] || fail "--from did not use the other id"
[[ ! -e "$REPO/machines/$OTHER" ]] || fail "--from left the other folder"
[[ -d "$REPO/machines/$HOST" ]] || fail "--from moved the current host folder"
[[ "$out" != *"$OTHER"* ]] || fail "--from printed the legacy name"

set +e
sl migrate --from '../outside' >/dev/null 2>&1
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "path segment was accepted"

# local env file cannot live in the repo
new_repo
LOCAL="$REPO/local.env"
set +e
out="$(sl setup 2>&1)"
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "setup wrote inside the repo"
[[ ! -e "$REPO/local.env" ]] || fail "salt file exists in the repo"
[[ "$out" == *"outside the repo"* ]] || fail "guard message: $out"
LOCAL="$HOME/.config/skill-locker/local.env"

# --- override precedence and opt-in extras ---
new_repo
mkdir -p "$REPO/shared/alpha" "$REPO/shared/beta" "$REPO/machines/box-a/alpha" "$REPO/machines/box-a/gamma" "$REPO/machines/box-b"
printf 'shared-alpha\n' > "$REPO/shared/alpha/SKILL.md"
printf 'shared-beta\n' > "$REPO/shared/beta/SKILL.md"
printf 'machine-alpha\n' > "$REPO/machines/box-a/alpha/SKILL.md"
printf 'machine-gamma\n' > "$REPO/machines/box-a/gamma/SKILL.md"
printf '# comment\n.agents/AGENTS.md\n' > "$REPO/machines/box-a/extras"
printf '\n' > "$REPO/machines/box-b/extras"
cp "$REPO/machines/box-a/extras" "$HOME/box-a.extras"
printf 'SKILL_LOCKER_SALT=%s\n' "$SALT" > "$LOCAL"
mkdir -p "$REPO/machines/$ID_HOST/only"
printf 'derived\n' > "$REPO/machines/$ID_HOST/only/SKILL.md"

SL_MACHINE='box-a'
sl link >/dev/null
[[ "$(readlink "$HOME/.agents/skills/alpha")" == "$REPO/machines/box-a/alpha" ]] || fail "machine skill did not override shared"
[[ "$(readlink "$HOME/.agents/skills/beta")" == "$REPO/shared/beta" ]] || fail "shared-only skill missing"
[[ "$(readlink "$HOME/.agents/skills/gamma")" == "$REPO/machines/box-a/gamma" ]] || fail "machine-only skill missing"
[[ "$(readlink "$HOME/.claude/skills/alpha")" == "$HOME/.agents/skills/alpha" ]] || fail "claude link"
[[ "$(readlink "$HOME/.agents/AGENTS.md")" == "$REPO/extras/.agents/AGENTS.md" ]] || fail "extra was not linked"
[[ ! -e "$HOME/.agents/lavish" ]] || fail "unlisted extra was linked"

SL_MACHINE='box-b'
sl link >/dev/null
[[ "$(readlink "$HOME/.agents/skills/alpha")" == "$REPO/shared/alpha" ]] || fail "other machine kept the machine override"
[[ ! -L "$HOME/.agents/skills/gamma" && ! -e "$HOME/.agents/skills/gamma" ]] || fail "machine-only skill leaked"
[[ ! -L "$HOME/.agents/AGENTS.md" && ! -e "$HOME/.agents/AGENTS.md" ]] || fail "extra stayed linked"
cmp -s "$REPO/machines/box-a/extras" "$HOME/box-a.extras" || fail "linking another machine rewrote the extras list"

sl use .agents/AGENTS.md >/dev/null
sl use .agents/AGENTS.md >/dev/null
[[ "$(grep -c '^\.agents/AGENTS.md$' "$REPO/machines/box-b/extras")" -eq 1 ]] || fail "use was not idempotent"
cmp -s "$REPO/machines/box-a/extras" "$HOME/box-a.extras" || fail "use rewrote the other machine"
[[ "$(readlink "$HOME/.agents/AGENTS.md")" == "$REPO/extras/.agents/AGENTS.md" ]] || fail "use did not link"
# comment on box-a is still not a path
[[ ! -e "$HOME/# comment" ]] || fail "comment was treated as a path"

# SKILL_LOCKER_MACHINE wins over a derived folder that also exists
SL_MACHINE='box-a'
[[ "$(sl machine-id)" == "box-a" ]] || fail "override lost to the derived id"
[[ "$(sl machine-id --derived)" == "$ID_HOST" ]] || fail "derived flag followed the override"
unset SL_MACHINE
[[ "$(sl machine-id)" == "$ID_HOST" ]] || fail "derived folder was not selected"
sl link >/dev/null
[[ "$(readlink "$HOME/.agents/skills/only")" == "$REPO/machines/$ID_HOST/only" ]] || fail "derived machine skill was not linked"
[[ "$(readlink "$HOME/.agents/skills/alpha")" == "$REPO/shared/alpha" ]] || fail "derived machine used another machine's override"

sl --help >/dev/null
set +e
sl not-a-command >/dev/null 2>&1
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "unknown command succeeded"

after_status="$(git -C "$ROOT" status --porcelain)"
[[ "$before_status" == "$after_status" ]] || fail "tests changed the real worktree"

echo "ok: skill-locker privacy migration checks"
