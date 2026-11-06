---
name: sol-loop
description: Review a change in a loop until it is approved, with GPT Sol on the whole diff, Haiku on hot spots, and a 3-provider council for one-way-door changes. Use when the user says "sol loop" or "council", asks to review and fix their own branch, PR, or work in progress, or asks for a review report on local changes. For feedback on a PR without fixing it, use review-pr.
---

# sol-loop

Review a change in rounds and fix between rounds, until the reviewers
approve. GPT Sol judges the whole diff. Up to 3 Haiku reviewers each dig
into one hot spot. On one-way doors, a council of three providers reviews
the whole diff.

Make the smallest changes that satisfy the reviewers. Fight scope creep,
and push back with evidence.

## Modes

| Mode | When | Whole-diff seats | Hot-spot seats |
| --- | --- | --- | --- |
| default | any review | Sol | ≤3 Haiku |
| council | user says "council", or the diff is a one-way door | Sol, Sonnet, Grok | ≤3 Haiku |
| report | user wants a review with no fixes | as default or council | as default or council |

A **one-way door** is a change that is hard to undo after it ships: a
schema or migration, deleting or rewriting stored data, auth, RLS or tenant
isolation, a public API contract or wire format that others read, or
infrastructure state (Terraform). When you pick council mode on your own,
say why in one line.

Report mode runs steps 1–3 once, fixes nothing, and replies in the report
format of `rubric.md`.

Seats use the newest model of each family in the `task` tool's model list:
Sol (`gpt-6.1-sol`), Sonnet (`claude-sonnet-5.5`), Grok (`grok-4.7`),
Haiku (`claude-haiku-5.5`). Use a version the user names. If a seat's model
is not available, report the blocker; a seat runs only on its own family.

## Budget

- Default: 3 rounds total. Round 1 is full. Later rounds check only
  changed code and open findings.
- Extend to 5 only for security, permissions, auth, data loss, or
  state/concurrency, while a blocker or should stays open with evidence. Or
  when the user asks.
- Stop early if a round returns only nits. Declined nits and comment,
  doc, or format-only fixes need no new round.
- Per round: one agent per seat. Reviewers must not start subagents.
- Keep a ledger: id, seat, severity, outcome, usage if returned. Never
  guess it.

## 1. Scope

Run `git status --short`. Do not stash, discard, or include unrelated
changes. Limit review to the change paths if they separate cleanly.
Otherwise stop and ask.

Find the base after `git fetch origin`:

- PR: `gh pr view <n> --json baseRefName,headRefOid`. Check out the branch
  only if clean. Confirm `HEAD` is the PR head, or ahead only by this
  change. Base: `git merge-base HEAD origin/<baseRefName>`.
- Local: `git merge-base HEAD origin/<default-branch>`. No remote: a base
  the user names, or `HEAD` for uncommitted changes only.

The change is base to working tree in those paths, with untracked files.
Use one diff command all rounds. State intent and out-of-scope in 1-2
sentences.

Except in report mode, fix known issues before round 1: open PR comments
and failing checks. Reviewers get the current implementation. Run covering
checks; note missing or pre-failing checks in the brief.

Gather for the brief:

- **Spec:** issue refs in commit messages or the PR (`#123`, `Closes #45`),
  a path the user gave, or a spec under `docs/`, `specs/` or `.scratch/`
  that matches the branch. If none, ask once; "none" is a valid answer.
- **Standards:** the files that document how code is written here
  (`AGENTS.md`, `CODING_STANDARDS.md`, `CONTRIBUTING.md`, and similar).
- **Load:** the expected load from the README or deploy config, such as
  one script run or many users at once.
- **Mode:** default, council or report, from the table above.

## 2. Hot spots

Rank the changed hunks by risk: one-way-door code first, then shared state
and concurrency, input parsing, money and time math, then the largest
behavior hunk. Take one hot spot per distinct risky area, at most 3, each
a `file:start-end` range of about 80 lines or fewer. A diff with no risky
hunk (docs, renames, formatting) gets no Haiku seat.

## 3. Start reviewers

Start every seat in one response with the `task` tool: `agent_type:
"code-review"`, `mode: "background"`, `model` set per seat. Elsewhere
(Claude Code, Codex, an Orca terminal), use native subagents on the same
models. Save each `agent_id`. Record model and effort only if exposed.

Do not edit scoped files while reviewers run. Wait for each completion
notice, then read each result once (`read_agent`). Timeout, error, or no
reply is not approval. On a failed seat: cancel, verify stop, restart it
with the ledger.

Ids are stable per seat: `S` Sol, `C` Sonnet, `G` Grok, `H1`–`H3` Haiku.

Whole-diff brief (Sol; Sonnet and Grok in council):

```
Review only. Do not edit, commit, push, comment on PRs, or start subagents.
Repo: <abs path> Base: <sha> Intent: <intent> Out of scope: <scope>
Checks: <results> Load: <expected load>
Spec: <path, URL, or "none"> Standards: <files>
Rubric: read <abs path to this skill>/rubric.md first.
See: git diff <base> [-- <paths>]; git status --short (read untracked).
Read the code the diff touches: callers of every changed function, the
functions it calls, the tests. Apply every lens in the rubric. Keep spec
and standards findings apart from the rest.
Hold to the smallest change. Flag code, tests, or guards the intent does
not need. Other paths, rare cases, small perf, extra compat: nits.
blocker = intended case wrong. should = real bug callers will hit, in
intent. nit = rest.
Reply:
VERDICT: APPROVE or CHANGES
SCORE: <n>/10                              (council only)
<id>1 [blocker|should|nit] [spec|standards|bug|risk|scale|test|speed|lean]
  <file>:<line> <claim>. Case: <input or situation -> wrong result>.
  Fix: <suggestion>
```

Hot-spot brief (one Haiku per hot spot):

```
Review only. Do not edit tracked files, commit, push, or start subagents.
Proof scripts go in /tmp/sol-loop-<id>/.
Repo: <abs path> Base: <sha> Intent: <intent>
Your slice: <file>:<start>-<end>. Read it and its direct callers and
callees. Stay inside the slice.
Hunt edge cases: empty, null, zero, one, last item, bounds, duplicates,
error paths, retries, time zones and rounding, concurrent callers, the
wrong tenant.
Each finding names a concrete input or situation and the wrong result.
When one small script or test proves it in a few minutes, write it under
/tmp, run it, and paste the command and output. No case, no finding.
At most 5 findings. "None found" is a valid answer.
Reply:
<id>.1 [blocker|should|nit] <file>:<line> <claim>.
  Case: <input -> wrong result>. Proof: <command + output, or "reasoned">.
  Fix: <suggestion>
```

## 4. Answer findings

Drop any finding with no concrete case before it reaches the ledger. Merge
duplicates across seats under the first id and note the others. Then check
each finding and severity yourself. Another path, rare case, or small cost
is a nit, whatever label it came with. When seats disagree, decide with
evidence.

- Agree: smallest fix. Prefer delete or narrow over new lock, cache,
  helper, or option. Fix the case that happened. Add one focused test
  that fails without the fix, if intent needs it.
- Disagree: say why, with evidence (file:line, test, output).
- Out of scope or nit: decline in one line. List as follow-up.

Update the ledger. Re-run checks and `git diff --shortstat <base>`. If
review grew the diff, cut first. Do not agree just to end the loop.

## 5. Next round

Start one only if budget remains and a blocker or should is open, behavior
code changed, or approval does not cover the current behavior diff.

- Whole-diff seats: follow up each saved agent ID (`write_agent` in Copilot
  CLI), or start fresh ones. Send the whole-diff brief, the ledger
  (`fixed:` / `disagree:` / `declined:` + evidence), the same base diff, and
  the change since last round. Ask for open ids and changed code only, with
  each old id marked `resolved` or `still open: <reason>`.
- Hot-spot seats: start a fresh Haiku only for a slice that a fix touched,
  at most 3.

## 6. Stop and ship

Agreed: every whole-diff seat says APPROVE on the current behavior diff, no
blocker or should is open, and you have no concern of your own. Stuck: an
item stays disputed after two replies, or budget ends. Show both sides in
2-3 lines each. The user decides. Budget end is not approval.

Do not push during the loop. Push after agreement only if the user asked
to push, ship, or update the PR. If you push to a PR, add above the model
blurb in the PR description (never as a comment):

- Default: `Reviewed with sol-loop: <N> rounds with <model>. Sol verdict: approved`.
  Add `on <effort>` only if verified.
- Council:

  ```markdown
  ## Council review

  Rounds: 2

  | Seat | Round 1 | Round 2 |
  | --- | --- | --- |
  | GPT Sol | 7/10 | 9/10 |
  | Claude Sonnet | 8/10 | 9/10 |
  | Grok | 6/10 | 9/10 |
  ```

  Write `no score` where a seat gave none; never invent one. With no PR, put
  the table in the final reply.

Report to the user: mode, rounds, models, what review changed, diff size
before/after, fixed and declined findings with reasons, usage if exposed
(else say not), pushed or not. In report mode, use the report format in
`rubric.md`.
