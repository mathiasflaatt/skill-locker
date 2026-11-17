### Pause safely

Explicit only. On "keep going" or "don't stop", do not pause.

1. Finish or back out of the current atomic step. Stop subagents and `pr-wait`.
2. Commit uncommitted edits as one `wip:` commit on the current branch. Push only if the branch already has a remote.
3. Write a resume note (intent, state, verified, next step, key files, gotchas) to a file, or use **handoff**.

**Reply:** where you stopped, the commits, whether the tree is clean, the first action on resume.
