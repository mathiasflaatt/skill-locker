### Feature

**You own the design. Delegate the code.**

1. Unclear scope or design: run `plan.md` first. A written spec: **implement-spec**.
2. Trace the affected subsystem. **architect** for the shape: data shape, types, module seams.
3. Throughput check, one line each: blocking first steps; independent workstreams (disjoint files parallelize in own worktrees); shared mutable state (split it); smallest safe decomposition.
4. Delegate code with file paths, the named data shape, and success criteria. Several valid shapes: **arena**. Test-first where cheap (**tdd**).
5. Verify on the real surface. Commit small, ordered units, each green.
6. Contested design: **interrogate** before shipping. Then `ship.md`.

**Reply:** what you built, what you chose and why, open decisions.
