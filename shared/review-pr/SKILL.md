---
name: review-pr
description: Review of a GitHub pull request (one GPT Sol seat; a council only when the PR touches auth or database migrations) in the PR-body format of the `pr` skill (Summary, Evidence, Merge Danger, linked issues) plus MoSCoW findings, shown in the session and optionally posted as a PR review. Use when the user says "review PR", gives a PR number or URL to review, or wants feedback on a PR without fixing it.
---

# review-pr

Review one pull request without fixing it. Verify its claims (evidence,
merge danger, closed issues) instead of trusting them, pick the review
depth with the council gate, sort findings into MoSCoW, and show the result
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

## 2. Council gate, merge danger and depth

**Council gate.** The council is expensive. Run it only when the PR
touches either of these; otherwise run one Sol seat:

- **Auth:** authentication or authorization code or config: login,
  sessions, tokens or JWTs, identity providers (OAuth, OIDC, Cognito,
  Entra), API keys and shared secrets, permission or role checks,
  policies, tenant guards and RLS.
- **Database migrations:** any migration file or schema change: an EF or
  other ORM migration, a `.sql` migration or runner script, a model
  snapshot, or a DbContext model change that needs a migration.

Check the changed file paths and the diff content; a path name alone is
not enough. Name the files that open the gate, or say "gate closed".

Rate the merge yourself from the diff, before the seats run:

- **Door:** one-way if it matches a `sol-loop` one-way door, else two-way.
- **Blast radius:** _contained_ (one module, internal callers only),
  _wide_ (a shared module, many callers, more than one project, data other
  services read), or _public_ (an external API contract, a wire format,
  deployed infrastructure, customer-visible behavior).

Depth follows the rating; apply every row that matches:

| Rating | Depth |
| --- | --- |
| gate closed | sol-loop default: one Sol seat (Astra for a UI diff; models per sol-loop "Modes"), high effort, no hot spots, no blast seat |
| gate open | council: Sol (or Astra), Sonnet, Grok, plus ≤3 Haiku hot spots |
| gate open and one-way door | ≤5 Haiku hot spots; name the one fact the merge is safe because of, and prove it by running code (blast-radius steps 2 and 5) |
| gate open and wide or public blast | add a blast seat (`claude-sonnet-5.5`) |

With the gate closed, still rate door and blast radius for the report and
tell Sol where the risk is. Say the gate, rating and depth in one line
before you start the seats.

## 3. Verify the evidence

In the worktree, run the tests or commands the Evidence section names. For
a new or changed test, also run it on `<base>` when that is cheap, to show
it fails before the change. Record each claim as _reproduced_ (command and
result), _not reproduced_ (command and what happened instead) or _not run_
(why). With no named evidence, run the tests that cover the changed files.

## 4. Seats

Gate open: find hot spots as `sol-loop` step 2 says, up to the cap from
step 2 here. Gate closed: skip hot spots. Start all seats in one response with the `sol-loop` step 3 briefs. Set
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

## Seats

| Seat | Score |
| --- | --- |
| GPT Sol | 7/10 |
| Claude Sonnet | 8/10 |
| Grok | no score |

Not checked: <one line, if any>
```

Number findings across groups, so the user can say "post 1 and 3". Skip
empty groups. With the gate closed, the Seats table has only GPT Sol. Write `no score` where a seat gave none; never invent one.

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
