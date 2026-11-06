---
name: review-pr
description: Council review of a GitHub pull request, reported as MoSCoW (Must, Should, Could, Won't), shown in the session and optionally posted as a PR review. Use when the user says "review PR", gives a PR number or URL to review, or wants feedback on a PR without fixing it.
---

# review-pr

Review one pull request with the council from `sol-loop`, sort the findings
into MoSCoW, show them in the session, then post them to the PR only if the
user says so. Read-only: one round, no fixes, no pushes.

Single sources in `~/.agents/skills/sol-loop/`: seats and one-way doors
(`SKILL.md` "Modes"), hot spots (step 2), briefs (step 3), lenses,
evidence and finding format (`rubric.md`). Use them as written.

## 1. Scope

```bash
gh pr view <n> --json number,url,title,body,author,baseRefName,headRefOid,files,closingIssuesReferences
gh pr view <n> --comments
```

Check out the head in a temporary worktree, so the user's tree stays as it
is:

```bash
git fetch origin pull/<n>/head <baseRefName>
git worktree add --detach /tmp/review-pr-<n> <headRefOid>
base=$(git merge-base <headRefOid> origin/<baseRefName>)
```

Gather for the brief, as `sol-loop` step 1 says: intent (PR title and body,
1-2 sentences), spec (linked issues), standards, load, and the checks status
from `gh pr checks <n>`. Also list the open review comments in one line
each, so the seats do not repeat them.

## 2. Council

Find hot spots as `sol-loop` step 2 says. Start all seats in one response:
the council whole-diff seats (Sol, Sonnet, Grok) and up to 3 Haiku seats,
with the `sol-loop` step 3 briefs. Set `Repo:` to the worktree, use
`git diff <base> <headRefOid>`, and add the line
`Already raised on the PR: <list>. Do not repeat these.`

Wait for each completion notice and read each result once. A failed seat is
reported in the output, not replaced by another model.

## 3. Triage into MoSCoW

Drop findings with no concrete case. Merge duplicates under the first id.
Check each finding against the code yourself; you, not the seat, set the
group:

| Group | Holds |
| --- | --- |
| **Must** | intended case wrong, security hole, data loss, breaks at the expected load, a one-way door done wrong |
| **Should** | a real bug callers will hit, a missing test on risky logic, a spec gap, real slowness |
| **Could** | lean wins, small speed-ups, standards and smell nits |
| **Won't** | findings you checked and rejected, or out of this PR's scope; one line why each |

## 4. Report in the session

```
## Review: <title> (#<n>)
What this PR does: <2-3 sentences>
Verdict: Approve | Request changes (any Must) | Comment

### Must
1. **<short title>** (`file:line`)
   - What this is / Problem / Fix / If we skip it   (rubric.md report format)
### Should
### Could
### Won't
- <id> <claim>: <why not>

| Seat | Score |
| --- | --- |
| GPT Sol | 7/10 |
| Claude Sonnet | 8/10 |
| Grok | no score |

Not checked: <one line, if any>
```

Number findings across groups, so the user can say "post 1 and 3". Skip
empty groups. Write `no score` where a seat gave none; never invent one.

## 5. Post, if asked

Ask with `ask_user` (single choice, default first):

- **Session only**: stop here.
- **Post Must + Should**: inline comments for those, summary in the body.
- **Post all**: Must, Should and Could inline; Won't stays in the session.
- **Pick**: the user lists numbers.

To post, load `leaving-pr-comments` and follow it for every comment body.
Send one review with all comments:

```bash
gh api repos/<owner>/<repo>/pulls/<n>/reviews --input review.json
```

`review.json`: `commit_id` = `<headRefOid>`, `event` = `COMMENT`, `body` =
the verdict, the score table and any finding whose line is not in the diff,
and `comments` = `[{path, line, side: "RIGHT", body}]`, one per posted
finding, each with its MoSCoW group in bold at the start. Use `APPROVE` or
`REQUEST_CHANGES` only when the user asks for it. Confirm the review URL
that GitHub returns.

## 6. Clean up

`git worktree remove /tmp/review-pr-<n>` and delete `/tmp/sol-loop-*`
proof folders. Report: the review URL or "session only", seats that
failed, usage if exposed.
