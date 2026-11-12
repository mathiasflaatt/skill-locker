---
name: fix-architecture-issues
description: Implement the open `improve-codebase` architecture issues, one T3 delegate per issue, each running the implement-spec flow to a ready PR. Use when the user says "fix architecture issues" or names `improve-codebase` issues to implement.
disable-model-invocation: true
---

You are the **orchestrator**. You pick the queue, start one **delegate** per issue, answer the delegates' questions, and link their PRs. The delegates write the code; you write none.

## 1. Build the queue

The `improve-codebase-architecture` flow files each finding as one GitHub issue with the `improve-codebase` label, a `severity:*` label and a triage label. The issue body has Finding, Proposed deepening, Acceptance criteria and Related. One issue is one **spec**; its acceptance criteria are its **tickets**.

- When the user names issues, the queue is those issues.
- Otherwise the queue is every open, unassigned issue with `improve-codebase` and `ready-for-agent`:
  `gh issue list --label improve-codebase --label ready-for-agent --state open --search "no:assignee" --json number,title,labels,body`
- Order by severity: `severity:high`, then `medium`, then `low`.

Issues with `deferred`, `needs-triage`, `needs-info` or `ready-for-human` stay out of the queue unless the user names them. List them in the final report as skipped.

Put two issues in one **lane** (run them one after the other) when they name the same files or one lists the other in Related. Issues in different lanes run in parallel.

Done when every queued issue is in exactly one lane, and you have claimed each with `gh issue edit <n> --add-assignee @me`.

## 2. Start one delegate per lane head

Call `orchestrator_capabilities` once. Then, for the first issue of each lane, call `delegate_task` with `isolation: "worktree"`, `role: "implementation"`, `mode: "async"`, and the brief below. When `SKILL_LOCKER_ASPIRE_MAX` in `~/.config/skill-locker/local.env` is a positive integer, at most that many running delegates may need the Aspire stack; queue the rest.

Brief (fill in `<n>`, `<title>` and `<owner/repo>` from `gh repo view --json nameWithOwner`):

> Implement GitHub issue #<n> "<title>" in <owner/repo>. Load the `implement-spec` skill and follow it: the issue is the spec, each unchecked acceptance criterion is a ticket. Start one native subagent per ticket, each in its own `git worktree add` checkout, as the skill says; set `model` on each spawn to the newest version of the chosen family. Read the issue body and its Related issues first; the Proposed deepening is the design, so keep to it.
>
> Name the integration branch `arch/<n>-<slug>`. Write the PR body with the `pr` skill and put `Closes #<n>` in it. When the change is user-visible and the repo has a `verify-platform` skill, prove it with that skill. Replace the final `code-review` step with `sol-loop`. Finish with a ready PR, all acceptance criteria ticked in the issue, and the verify gate from the repo's `AGENTS.md` green.
>
> When a decision is open, find the answer first in the issue, its Related issues, the repo's ADRs, domain docs, glossaries and code. Ask a question with your ask-question tool only when none of these answers it and a wrong guess would change the design. Put the options and your recommendation in the question.
>
> Last line: PR <full URL>, head <SHA>, checks and reviews <state>.

Done when each lane head has a `taskId` and you have recorded it beside its issue.

## 3. Answer questions

A delegate question wakes you as a pending request. Read it with `t3_pending_request` (`action: "read"`, the child `threadId`).

1. Find the answer from the same sources the brief names, plus the other issues in the queue. Answer with `t3_pending_request` (`action: "respond"`) and say which source decided it.
2. When no source decides it, ask the user with your ask-question tool. Give the issue, the options, the delegate's recommendation and yours. Relay the answer to the delegate, and add a short comment on the issue so the decision is on record.

Contact the user directly only when the work cannot continue without the user's answer. Other delegates keep running while one waits.

## 4. Collect results

When a delegate finishes, read it with `task_status`.

- **Ready PR:** link it with `link_pull_request`. Check that the issue's acceptance criteria are ticked. Start the next issue in that lane (step 2).
- **Blocked or failed:** comment on the issue with the blocker and what is done, remove your assignee, and start the next issue in that lane. Tell the user in the final report.

Done when every queued issue has a linked ready PR or a blocker comment.

## 5. Report

Give one table: issue (linked title), severity, PR, state (ready, blocked, skipped) and the open item, if any. List the decisions you made for the delegates, so the user can overrule them in review.
