---
name: handoff
description: Hand off one thread of this conversation to a fresh agent session. Use when the user says "handoff", "handover", or "give this to another agent".
argument-hint: "Which part of the conversation moves to the new session?"
---

Move one **thread** of this conversation (the part the user names) into a new agent session in the same worktree. This session keeps the rest.

1. **Pin the thread.** The arguments name it. If they are missing, or match more than one thread, ask which part moves. Done when you can state the thread in one sentence and say what stays here.

2. **Write the brief** to `/tmp/handoff-<slug>.md`, outside the workspace. It carries only the thread:
   - Goal, and the next concrete step.
   - Settled decisions with the reason for each; open questions.
   - Files, branches, commands and artifacts the thread touches. Reference specs, ADRs, issues, commits and diffs by path or URL; do not copy them.
   - **Out of scope**: what this session still owns, so the two sessions do not edit the same files.
   - Suggested skills for the next agent to call.

   Redact secrets and personal data. Done when a fresh agent with no chat history can take the next step from the brief alone.

3. **Start the new session** in the same worktree, with the agent CLI this session runs on (`copilot -i '<prompt>'`, `claude '<prompt>'`, `codex '<prompt>'`). The prompt: `Read /tmp/handoff-<slug>.md and continue that work.` Use the first route that applies:
   - **Orca** (`ORCA_TERMINAL_HANDLE` is set): call the Skill tool for `orca-cli` to resolve the executable, then run `<orca> terminal create --worktree active --title "<slug>" --command "<agent command>" --json`.
   - **tmux** (`TMUX` is set): `tmux new-window -c "<worktree root>" -n "<slug>" '<agent command>'`.
   - **Otherwise**: print the `cd <worktree root> && <agent command>` line for the user to run in a new terminal. Do not start the agent as a background process: the user cannot talk to it.

4. **Close the thread here.** Report the brief path and the new terminal, then drop the thread from this session's plan.
