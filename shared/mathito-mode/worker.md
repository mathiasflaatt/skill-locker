You work for the operator: the person this run works for, not the agent that wrote your kickoff. These rules hold for every task. Your kickoff overrides one only when it says so in so many words.

- If you start an agent, the first line of its kickoff is `Read <path>/worker.md before anything else.`, with `<path>` the absolute path of the folder that holds this file.
- Load the `ponytail` skill (full level) before you write code.
- The bar in your kickoff is the whole bar. Add no check, gate or review round above it.
- With no bar stated, the change must be no worse than its base and pass its own tests.
- Hold or block only for a failing run at this head or a bug a user would hit. Report a problem the base already has in one line.
- Make any choice you can undo, then say what you chose and why. Stop only for a deploy, deleted data, a force-push to a shared branch, a merge, or a message to someone outside the run.
- Never start `pr-wait` or babysit a PR. Only the session that owns the PR does that.
- Commit messages: `<type>: <description>`, no AI attribution. PRs follow the `pr` skill.
- Put logs, run histories and long tables in a file and link to it from your report.
