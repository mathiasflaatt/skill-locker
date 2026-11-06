---
name: review-pr
description: Council review of a GitHub pull request in the PR-body format of the `pr` skill (Summary, Evidence, Merge Danger, linked issues) plus MoSCoW findings, shown in the session and optionally posted as a PR review. Use when the user says "review PR", gives a PR number or URL to review, or wants feedback on a PR without fixing it.
---

# review-pr

Review one pull request without fixing it. Verify its claims (evidence,
merge danger, closed issues) instead of trusting them, scale the review to
how dangerous the merge is, sort findings into MoSCoW, and show the result
in the session. Post to the PR only if the user says so.

Single sources, used as written:

- `~/.agents/skills/sol-loop/SKILL.md`: seats and one-way doors ("Modes"),
  hot spots (step 2), seat briefs (step 3).
- `~/.agents/skills/sol-loop/rubric.md`: lenses, evidence rule, finding
  format.
- The `pr` skill: the repo's `.claude/skills/pr/SKILL.md` if present, else
  `~/.agents/skills/pr/SKILL.md`. Its PR-body sections and Summary visuals
  shape the report.
- `~/.agents/skills/blast-radius/SKILL.md`: the blast seat's method.

## 1. Scope

```bash
gh pr view <n> --json number,url,title,body,author,baseRefName,headRefOid,files,closingIssuesReferences
gh pr view <n> --comments
gh pr checks <n>
```

Check out the head in a temporary worktree, so the user's tree stays as it
is:

```bash
git fetch origin pull/<n>/head <baseRefName>
git worktree add --detach /tmp/review-pr-<n> <headRefOid>
base=$(git merge-base <headRefOid> origin/<baseRefName>)
```

Gather intent (title and body, 1-2 sentences), standards and load as
`sol-loop` step 1 says, and the open review comments in one line each.

**Issues.** For every `Closes #`, `Fixes #`, `Part of #` line and every
`closingIssuesReferences` entry, run `gh issue view <i> --json
number,title,body,state`. List each issue's acceptance criteria: checklist
items, "must"/"should" statements, or the problem it states. These are the
spec for the seats.

**Claims.** Copy the PR body's Evidence and Merge Danger sections as the
author's claims. Missing sections are claims of "none".

## 2. Merge danger and depth

Rate the merge yourself from the diff, before the council runs:

- **Door:** one-way if it matches a `sol-loop` one-way door, else two-way.
- **Blast radius:** _contained_ (one module, internal callers only),
  _wide_ (a shared module, many callers, more than one project, data other
  services read), or _public_ (an external API contract, a wire format,
  deployed infrastructure, customer-visible behavior).

Depth follows the rating; apply every row that matches:

| Rating | Depth |
| --- | --- |
| any | council: Sol, Sonnet, Grok, plus ≤3 Haiku hot spots |
| one-way door | ≤5 Haiku hot spots; name the one fact the merge is safe because of, and prove it by running code (blast-radius steps 2 and 5) |
| wide or public blast | add a blast seat (`claude-sonnet-5.5`) |

Say the rating and depth in one line before you start the seats.

## 3. Verify the evidence

In the worktree, run the tests or commands the Evidence section names. For
a new or changed test, also run it on `<base>` when that is cheap, to show
it fails before the change. Record each claim as _reproduced_ (command and
result), _not reproduced_ (command and what happened instead) or _not run_
(why). With no named evidence, run the tests that cover the changed files.

## 4. Council

Find hot spots as `sol-loop` step 2 says, up to the cap from step 2 here.
Start all seats in one response with the `sol-loop` step 3 briefs. Set
`Repo:` to the worktree, use `git diff <base> <headRefOid>`, put the issue
criteria in `Spec:`, and add:

```
Already raised on the PR: <list>. Do not repeat these.
Author claims Door: <claim>, Blast Radius: <claim>. Say if the diff disagrees.
```

Blast seat brief:

```
Review only. Do not edit tracked files, commit, push, or start subagents.
Proof scripts go in /tmp/review-pr-<n>-blast/.
Repo: <worktree> Base: <sha> Intent: <intent>
Follow ~/.agents/skills/blast-radius/SKILL.md steps 1-5 for git diff <base> <headRefOid>.
Look past the diff: callers in other projects, DB columns, wire formats,
API consumers, feature flags, deploy config.
Reply: the safety fact (proven or unproven), risks with file:line, how
likely and how bad, and what you cleared.
```

Wait for each completion notice and read each result once. Report a failed
seat in the output; a seat runs only on its own model.

## 5. Triage

Drop findings with no concrete case. Merge duplicates under the first id.
Check each finding against the code yourself; you, not the seat, set the
group:

| Group | Holds |
| --- | --- |
| **Must** | intended case wrong, security hole, data loss, breaks at the expected load, a one-way door done wrong, a `Closes` issue with a missing criterion, a claimed two-way door that is one-way |
| **Should** | a real bug callers will hit, a missing test on risky logic, a partial criterion, evidence not reproduced or missing, an understated blast radius |
| **Could** | lean wins, small speed-ups, standards and smell nits, an issue this PR resolves but does not link |
| **Won't** | findings you checked and rejected, or out of this PR's scope; one line why each |

Verdict: _Request changes_ with any Must, _Approve_ with no Must or Should,
else _Comment_.

## 6. Report in the session

Mirror the `pr` skill's sections, with your verified view next to the
author's claims:

```markdown
# Review: <title> (#<n>)

**Verdict:** <verdict> · **Depth:** <rating and depth from step 2>

## Summary

<one visual chosen as the pr skill's Summary section says; note where it
differs from the author's summary>

## Evidence

- **Claimed:** <author's evidence>
  **Verified:** <reproduced | not reproduced | not run>: <command → result>

## Merge Danger

**Door:** <claimed> → <assessed>. <why, if they differ>

**Blast Radius:** <claimed> → <assessed>. <ramifications; the safety fact
and its proof, when step 2 asked for one>

## Linked issues

| Issue | Criterion | Status | Where |
| --- | --- | --- | --- |
| #<i> | <criterion> | done / partial / missing | `file:line` |

## Findings

### Must
1. **<short title>** (`file:line`)
   - **What this is / Problem / Fix / If we skip it** (rubric.md report format)

### Should
### Could
### Won't
- <id> <claim>: <why not>

## Council

| Seat | Score |
| --- | --- |
| GPT Sol | 7/10 |
| Claude Sonnet | 8/10 |
| Grok | no score |

Not checked: <one line, if any>
```

Number findings across groups, so the user can say "post 1 and 3". Skip
empty groups. Write `no score` where a seat gave none; never invent one.

## 7. Post, if asked

Ask with `ask_user` (single choice, default first):

- **Session only**: stop here.
- **Post Must + Should**: inline comments for those.
- **Post all**: Must, Should and Could inline; Won't stays in the session.
- **Pick**: the user lists numbers.

To post, load `leaving-pr-comments` and follow it for every comment body.
Send one review with all comments:

```bash
gh api repos/<owner>/<repo>/pulls/<n>/reviews --input review.json
```

`review.json`: `commit_id` = `<headRefOid>`, `event` = `COMMENT`, `body` =
the report without the Findings section, plus any posted finding whose line
is not in the diff, and `comments` = `[{path, line, side: "RIGHT", body}]`,
one per posted finding, each starting with its MoSCoW group in bold. Use
`APPROVE` or `REQUEST_CHANGES` only when the user asks for it. Confirm the
review URL that GitHub returns.

## 8. Clean up

`git worktree remove /tmp/review-pr-<n>`, and delete `/tmp/review-pr-<n>-*`
and `/tmp/sol-loop-*` proof folders. Report: the review URL or "session
only", depth used, seats that failed, usage if exposed.
