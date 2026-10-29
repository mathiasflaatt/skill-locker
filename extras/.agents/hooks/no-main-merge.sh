#!/usr/bin/env bash
# PreToolUse guard (Copilot CLI + Claude Code): agents must not merge into the
# base branch of a protected repo. full-send is blocked at the merge step; use
# full-stop and let the user merge.
# Protected repos come from SKILL_LOCKER_PROTECTED_REPOS in
# ~/.config/skill-locker/local.env, as space-separated "owner/repo:branch" pairs.
# Always exits 0: a non-zero exit makes Copilot deny every tool call.

LOCAL_ENV="${SKILL_LOCKER_LOCAL_ENV:-$HOME/.config/skill-locker/local.env}"
# shellcheck disable=SC1090
[ -f "$LOCAL_ENV" ] && . "$LOCAL_ENV" 2>/dev/null
[ -n "${SKILL_LOCKER_PROTECTED_REPOS:-}" ] || exit 0

input=$(cat 2>/dev/null) || exit 0
q() { jq -r "$1" <<<"$input" 2>/dev/null || true; }

tool=$(q '.toolName // .tool_name // empty')
case "$tool" in bash|Bash) ;; *) exit 0 ;; esac

cmd=$(q '(.toolArgs | if type=="string" then (fromjson? // {}) else (. // {}) end | .command) // .tool_input.command // empty')
[ -n "$cmd" ] || exit 0
cwd=$(q '.cwd // empty'); [ -d "$cwd" ] || cwd=$PWD
claude=$(q 'has("hook_event_name")')

origin=$(git -C "$cwd" remote get-url origin 2>/dev/null)
REPO=""; BASE=""
for entry in $SKILL_LOCKER_PROTECTED_REPOS; do
  r=${entry%%:*}; b=${entry#*:}; [ "$b" = "$entry" ] && b=main
  case "$origin $cmd" in *"$r"*) REPO=$r; BASE=$b; break ;; esac
done
[ -n "$REPO" ] || exit 0

deny() {
  local reason="Blocked by personal hook: in $REPO, agents must not merge into $BASE ($1). full-send is not allowed here; use full-stop: leave the PR ready and unmerged, and hand it to the user to merge."
  if [ "$claude" = true ]; then
    jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  else
    jq -nc --arg r "$reason" '{permissionDecision:"deny",permissionDecisionReason:$r}'
  fi
  exit 0
}

# gh pr merge [<pr>] [-R repo] ...: allow only when the PR base is known and is not main.
if grep -Eq '(^|[^[:alnum:]_-])gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)' <<<"$cmd"; then
  rest=$(sed -E 's/.*gh[[:space:]]+pr[[:space:]]+merge//' <<<"$cmd" | sed -E 's/[;&|].*//')
  read -r -a words <<<"$rest"
  pr=""; repo_args=()
  for ((i = 0; i < ${#words[@]}; i++)); do
    w=${words[i]}
    case "$w" in
      -R|--repo) repo_args=(-R "${words[i+1]}"); i=$((i + 1)) ;;
      --repo=*) repo_args=(-R "${w#--repo=}") ;;
      -t|-b|-F|--subject|--body|--body-file|--author-email|--match-head-commit) i=$((i + 1)) ;;
      -*) ;;
      *) [ -z "$pr" ] && pr=${w//[\"\']/} ;;
    esac
  done
  base=$(cd "$cwd" && timeout 8 gh pr view $pr "${repo_args[@]}" --json baseRefName -q .baseRefName 2>/dev/null)
  [ -n "$base" ] && [ "$base" != "$BASE" ] && exit 0
  deny "gh pr merge, base ${base:-unknown}"
fi

# REST or GraphQL merge / auto-merge.
if grep -Eq 'gh[[:space:]]+api' <<<"$cmd" &&
   grep -Eq '/pulls/[0-9]+/merge|mergePullRequest|enablePullRequestAutoMerge|enqueuePullRequest' <<<"$cmd"; then
  deny "merge through gh api"
fi

# Direct push to main.
if grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]+push([[:space:]]|$)' <<<"$cmd" &&
   grep -Eq '[[:space:]:+](refs/heads/)?'"$BASE"'([[:space:];&|]|$)' <<<"$(sed -E 's/.*git[[:space:]]+push//' <<<"$cmd")"; then
  deny "git push to $BASE"
fi

exit 0
