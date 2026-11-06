# sol-loop rubric

Reviewers read this file before they review. The orchestrator uses
"Report format" for the final report.

## Lenses

Order of importance: correct, safe, holds under load, tested, fast, lean.

1. **Bug:** wrong result, crash, missed edge case (empty, zero, last item,
   rounding, time zones), a caller broken by the change, a fix applied in one
   caller while the shared function stays broken.
2. **Risk:** security holes (injection, weak randomness, secrets, missing
   checks on user input), data loss (swallowed errors, writes in the wrong
   order, no transaction), tenant data that leaks across tenants.
3. **Scale:** fine for one user, wrong at the expected load: check-then-write
   races, the same work done by every process, lists or memory that only
   grow, a query per item, O(n^2) on big input, per-process state that must
   be shared. Judge against the load in the brief.
4. **Missing test:** risky new logic (a branch, a parser, money, security,
   data writes, a bug fix) with no test that fails when it breaks. One good
   test, not coverage.
5. **Speed:** a big slowdown is a finding. Small wins are nits.
6. **Lean:** code that should not exist or should be smaller.
   - delete: dead code, unused options, speculative features
   - reuse: the repo already has this helper (name the path)
   - stdlib: the standard library or platform already does it
   - yagni: abstraction with one implementation, config nobody sets
   - merge: near-copies that must change together
   - split: one function doing unrelated jobs. Split by job, never by line
     count.

A `shortcut:` (or older `ponytail:`) comment that names its limit is a
decision, not a finding, unless the expected load already crosses it.

## Evidence

Every bug, risk, scale and test finding names a concrete case: this input
or situation leads to this wrong result. No case, no finding. Re-read the
lines first: the caller exists, the value can really be empty, the code
really is unused. Propose the smallest fix; prefer fixes that delete code.

## Spec axis

Report apart from the other findings, and quote the spec line for each:

- asked for, but missing or partial
- in the diff, but not asked for (scope creep)
- looks implemented, but the implementation is wrong

## Standards axis

The repo's documented standards (`AGENTS.md`, `CODING_STANDARDS.md`,
`CONTRIBUTING.md` and similar), plus the smell baseline below. Cite the file
and rule. Skip what tooling already enforces.

The repo overrides the baseline: where a documented standard endorses
something a smell would flag, drop the smell. A smell is always a nit,
labelled "possible <smell>".

Smell baseline (Fowler, _Refactoring_ ch. 3), each as what it is → fix:

- **Mysterious Name:** the name hides what it does or holds → rename.
- **Duplicated Code:** the same logic shape in more than one hunk → extract.
- **Feature Envy:** a method uses another object's data more than its own →
  move it to that data.
- **Data Clumps:** the same fields travel together → one type.
- **Primitive Obsession:** a string or number stands in for a domain concept
  → a small type.
- **Repeated Switches:** the same switch on the same type recurs → one map
  or polymorphism.
- **Shotgun Surgery:** one logical change scatters edits across many files →
  gather into one module.
- **Divergent Change:** one module edited for unrelated reasons → split.
- **Speculative Generality:** hooks or parameters the spec does not need →
  delete.
- **Message Chains:** long `a.b().c().d()` walks → one method on the first
  object.
- **Middle Man:** a class that only delegates → call the target.
- **Refused Bequest:** a subclass ignores what it inherits → composition.

## Report format

Very simple English: short sentences, everyday words. Explain a technical
term the first time. The reader may never have seen this code.

Start with `What this change does:` in two or three sentences. Then the
findings in three groups, skipping empty groups:

- **Must fix:** bug, security, data loss, breaks at the expected load.
- **Should fix:** risky code without a test, real slowness, duplication, a
  function that mixes jobs, code that should not exist.
- **Nice to have:** small speed-ups, shorter forms, smells.

Number findings across all groups. Each finding has four parts of one or two
short sentences:

2. **Orders land on the wrong day** (`billing/close_day.py:L40-52`)
   - **What this is:** At midnight this job bills all orders of that day.
   - **Problem:** It takes "today" from the UTC server clock, so an order
     at 00:30 in Berlin is billed on the day before.
   - **Fix:** Compute the day in the shop's time zone. One line.
   - **If we skip it:** Late orders show the wrong date.

End with `Verdict: Ship.` or `Verdict: fix 1 and 3 first.`, then
`Lean: -<N> lines possible.` when lean findings exist, then
`Not checked:` in one line if something mattered and you could not check it.
