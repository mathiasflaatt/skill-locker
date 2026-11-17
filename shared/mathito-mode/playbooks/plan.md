### Plan

**You own the plan, not the code. The plan is the deliverable. Do not implement.**

1. One or two files with an obvious approach: skip the plan, say so, go to Feature or Bug fix.
2. Settle what a run can settle by prototype (`prototype.md`) before you ask.
3. **Grill.** Load **grill-with-docs** (it loads **grilling** and **domain-modeling**). Ask only product or preference calls no run can settle. Record terms in the glossary and hard-to-reverse decisions as ADRs as you go.
4. **Show.** Load **explaining-visually**. Write one page per topic with `<h1 data-mode="plan">`: what changes and why, today versus after, the steps (one commit or one PR each), the dependency graph (which PRs branch from trunk, which wait, the files each touches), and where in the code. Put each open question on the page as a `.q`, not in chat. Run the comment loop until all `.q` are answered.
5. **Verification per step.** Each step names its unit check, its live check on the real surface (scenario + pass predicate), and for perf work the metric and trunk baseline. Tests alone are not verification.
6. **Approve.** Wait for `APPROVE` from the page or an explicit go in chat. Then turn the plan into **to-spec** (one PR) or **to-tickets** (many). Work larger than one session: **wayfinder** instead.

**Reply:** the page URL, the steps in landing order with dependencies, what stays unproven.
