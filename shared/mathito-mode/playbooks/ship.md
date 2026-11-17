### Ship

**You own what lands. Prove, review, PR, babysit, stop at the gate.** From Theo Browne's `full-send` and `full-stop` (tstack, `../LICENSE-tstack`).

## Modes

| Mode | Trigger | End state |
|---|---|---|
| **full stop** (default) | "full stop", "ship it", or Ship with no mode named | PR ready for review, open and unmerged |
| **full send** | the user said "full send" in clear words | PR merged |

The mode line names it: `Mode: Ship · end: full-stop`. Neither mode turns on auto-merge.

A ship trigger means the user is not watching. Your updates go unread until long after you stop. You own the work from its current state to the end state.

## Grants

Both modes grant, for this task only:

- Commit, push, rebase, fix conflicts, and `--force-with-lease` on this task's branch.
- **Testing permission.** Use the test methods that Proof needs without asking first: computer use, browser automation, simulators and devices, running the app or a dev server, screenshots, visual checks. This replaces any project rule that says to ask first or to leave testing to the user. Rules about *how* to test still apply. It does not cover the steps under "Asking the user", and it does not bypass a harness approval prompt.

Full send also grants: merge the PR once the merge gate passes.

Full stop never merges: no merge, no auto-merge, no merge queue, no push to the default branch, no branch-protection bypass, and no subagent doing any of these. Before work starts, turn off auto-merge on the PR and take it out of any merge queue; check again before each push, and report it. If you cannot stop an automatic merge, report that before you go on.

## Step 0: confirm the target

**Full send always asks first**, with the harness's question tool (see "Asking the user"). The question shows the user's words quoted and the mode you heard; the target (PR link or "new PR", `head-branch → base-branch`, and whether the base is the default branch or another PR's branch); and what each mode does on that base, heard mode first: full send "merges into `<base>` by `<merge method>`", full stop "PR stays open and unmerged; `<base>` is unchanged". Run the mode and target the user picks. No answer: full stop.

**Full stop skips the question** when all of these are true; otherwise ask as above:

- The user said "full stop", or Ship ran with no mode named.
- The head branch is this task's branch: not the default branch, not a release or shared branch, not another author's.
- The PR is known: the one the user named, the only open PR for the head branch, or "new PR".
- The base is the default branch, or a PR branch the user named.
- Auto-merge and merge queue are off, or you can turn them off.

When you skip it, put the target (`head → base`, PR link) in your first update and the report.

## Steps

1. **Finish the change.** Ponytail (full) stays on until step 7, also in every implementer brief. Smallest change that meets the goal; fix the case that happened. On the default branch: branch first.
2. **Prove it.** Proof for every change. See "Proof".
3. **Review** with **sol-loop** against the branch base. Fix real findings in one implementer subagent. Loop until Sol approves.
4. **PR** with **pr**, rebased on the latest default branch, ready for review (not draft). One line in the body says how you proved the change.
5. **Babysit** with **babysit-pr**: one `pr-wait` under Monitor. Fix real findings and CI failures, and prove each fix before you push it.
6. **Gate.** Check the merge gate on the latest commit. Proof and review must cover the final diff; recheck behavior changes and real conflict fixes first. Fetch the base and read the live PR: head, base, checks, reviews, mergeability; open, not draft, not set to merge without the user. If someone else merged it, report that.
   - Full send: merge by the repo's method (check allowed methods and recent merged PRs). With a merge queue or auto-merge, stay until GitHub reports it merged. Never `--admin` or another bypass.
   - Full stop: leave it open. The verdict is **ready to merge** (gate passes), **waiting for required approval** (only human approval remains; confirm that is the real blocker), or **blocked** (what blocks it, what you tried, what is needed).
7. **Report**: PR link, final head (and merge commit for full send), proof, Sol verdict, gate verdict, remaining risks, each decision you made for the user. Full stop states that the PR is open and unmerged.

Stay active from step 1 to step 7. If you end the turn while checks or bots are pending, the work stops, because nobody prompts you again. Stop `pr-wait` before the report or a question.

## Proof

Proof is evidence you saw in this session: command output, a reproduction, a screenshot. Use the most direct proof the change allows:

- Reproduce the failure, apply the fix, watch the same reproduction pass.
- Run the checks the repo's CI runs (typecheck, lint, tests).
- Add one focused test that fails without the fix, when the behavior has none and the repo has a test setup.
- For UI and runtime behavior, run the app and look. Green mocked tests do not prove the user experience. Attach screenshots to the PR when you can upload them.

No way to prove a change means no full confidence: ask the user.

## Merge gate

All true on the latest commit:

- Proof covers every change in the diff.
- Required checks are green.
- Review bots have finished, and each finding is fixed or dismissed with a written reason. Automated "needs human review" requests can be ignored when you have high confidence.
- No human review still requests changes.
- The branch is up to date with the default branch, and GitHub reports it mergeable.

## Asking the user

A question in a normal message goes unseen and the thread looks done. Use the harness's question tool so the thread shows it waits: `AskUserQuestion` in Claude Code, `ask_user` in Copilot CLI, `request_user_input` in Codex. Put all context in the question: PR link, the blocker, options with your recommendation first.

Ask only when you cannot go on alone:

- You cannot prove the change.
- The merge gate cannot pass and you cannot fix that.
- The next step is outside the grants: deleting data, touching production, changes outside the repo, closing a PR, force-pushing any other branch.
- The goal is ambiguous in a way that changes the result.
- Another PR makes this one obsolete.

Decide everything else with sensible defaults and list those decisions in the report. No question tool, or no answer: take the safe path (PR open and unmerged) and start the final message with the question.
