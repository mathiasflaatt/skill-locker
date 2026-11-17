### Swarm

**You own the frame and the verdict. Workers own one slice each.** For parallel coverage, races, gauntlets and exploration that return one report. One code change with coupled files is Feature, not a swarm.

1. **Frame.** State the done predicate and the report the swarm returns. Pick the shape: partition into slices, race N workers on one brief, or both. For a race, declare the rule first: `first pass`, `rank all` or `best-of`.
2. **Briefs.** Each brief stands alone: goal, scope, the exact slice or race arm, how to verify, what to report. A worker that writes gets its own `git worktree` (absolute path in the brief). A worker that verifies or measures gets the exact SHAs, and for a measurement the method (sample count, what one sample is, order).
3. **Fan out.** Spawn all workers in one message, background mode, model per AGENTS.md "Subagent delegation". Workers that run the Aspire stack count against its limit of 2; queue the rest. Reports use `PASS`, `ISSUES` or `BLOCKED` with evidence; an `ISSUES` worker lists every issue it can prove.
4. **Aggregate.** Drop a result that lacks the SHAs or method its brief names and respawn that worker once; a second miss is a gap, and a gap is not a pass. Coverage needs a result per slice. A race applies the declared rule. A worker that drops out: go on with N-1 and say so.
5. **Merge** written slices one at a time through a merger subagent (AGENTS.md).

**Reply:** one table of results, issue one-liners, gaps or dropouts, the race rule when used.
