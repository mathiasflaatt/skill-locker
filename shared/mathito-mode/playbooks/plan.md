### Plan

**You own the plan, not the code. The plan is the deliverable. Do not implement.** The `planning` skill and mathito-mode both run this file.

## 1. Route

One or two files with an obvious approach: skip the plan, say so, go to Feature or Bug fix.

Otherwise size the scope, then ask the user to pick the route with the harness's question tool (`AskUserQuestion` in Claude Code, `ask_user` in Copilot CLI), your recommendation first, each option with one line on why it fits or not:

| Route | Scope | Output |
|---|---|---|
| **grill-with-docs** | An idea or design still loose. The user's thinking needs a stress test before anything is written. | Settled decisions, glossary terms, ADRs |
| **to-spec** | One PR's worth, already discussed. | One spec on the issue tracker |
| **Multi-PR plan** (section 3) | Several PRs or phases, one session can hold it. | A plan page with PRs, dependencies, verification |
| **wayfinder** | Bigger than one session, wrapped in fog. | A map of decision tickets on the issue tracker |

Routes chain: a loose idea runs grill-with-docs first, then the route its result fits. Put the chosen route in the mode line: `Mode: Plan (grill-with-docs → to-spec)`.

## 2. Rules for every route

- **Visual.** Load **explaining-visually** and keep one page per topic, `<h1 data-mode="plan">`. Each route shows its work there, not in chat:
  - grill-with-docs: each grill question is a `.q` on the page, recommended answer marked `rec`; decisions and new glossary terms land on the page as they settle.
  - to-spec: the spec as a page (what changes and why, today versus after, steps, where in the code) before you publish it.
  - Multi-PR plan: section 3.
  - wayfinder: the map (destination, decision tickets, which waits on which) as a drawing that links each ticket.

  Run the page's comment loop until every `.q` is answered.
- **Planner model.** Subagents that plan, design, research for the plan, or review it run one tier above normal work: in Claude Code `model: "fable"`; if the schema or the account rejects it, `model: "opus"` with `effort: "xhigh"`. In Copilot, the newest top-tier model. Name the model in the brief and the report. Implementation after approval goes back to AGENTS.md's normal choice.
- **Settle by running.** A question a prototype can answer goes to `prototype.md`, not to the user. Ask only product or preference calls.
- **Approve.** Wait for `APPROVE` from the page or a clear go in chat. Then publish (spec, tickets, map) or hand to the playbook that builds it. Execution starts only on the user's go.

## 3. Multi-PR plan

1. Open with what changes, the PR ids in landing order, and the dependency graph: which PRs branch from trunk, which wait for which, and the files each may touch.
2. One section per PR. One PR is one change with its own evidence (`sequence-verifiable-units`). Each has tick-off boxes (`data-check`) for what it depends on, the files it edits, the one change it builds, the result you see, and its verification.
3. Tests alone are not verification. A PR is verified when its unit, live and (for perf work) perf boxes are all checked. A live box drives the real surface with a scenario and a pass predicate. A perf box names the metric, the probe, the trunk baseline measured first, and the number that fails.
4. After approval: **to-tickets** for the PRs, or **implement-spec** to build them.

**Reply:** the route, the page URL, what was published or approved, what stays unproven.
