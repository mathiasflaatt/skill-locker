# Reporting

When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

# Prose output

Write prose output (reports, tickets, commit messages, PR descriptions, docs) in 80% ASD-STE100. Domain terms from GLOSSARY-MAP.md, GLOSSARY.md, or CONTEXT.md win over the STE word list.

# File edits

Prefer `edit`. Script (`sed`/python) OK for many-place/many-file changes; fail on no match, check `git diff`.

# Subagent delegation

- Delegate with native inline subagents (Copilot `task`, Claude Code `Agent`); run them in background mode and act on the completion notification.
- Give each parallel implementer its own `git worktree add` checkout and pass it the absolute path. Reviewers read the committed diff.
- Integrate each reviewed slice through a merger subagent: it merges into the integration branch, resolves conflicts, runs the verify gate, and reports the merge commit. Run one merger at a time.
- For a full ownership handoff, use the `handoff` skill. Use the Orca CLI only when the user asks for Orca; load `orca-cli` first and follow its guide.
- Set `model` on every subagent spawn to the newest version of the chosen model family in the tool's model list (for example `gpt-6-luna`, not `gpt-5.6-luna`). The harness default for `explore` is an older version, so an omitted `model` does not give the newest version.
- When `SKILL_LOCKER_ASPIRE_MAX` in `~/.config/skill-locker/local.env` is a positive integer, at most that many agents may run the Aspire stack (`aspire start`, Docker/startup tests) at once. Queue further Aspire-running slices. Agents doing only build/unit tests may run alongside. When the variable is unset, do not add a cap.

# Feedback loops use Lavish

When a session collects user feedback (planning, grilling, wayfinding, brainstorming, design or scope decisions), load the `lavish` skill and run the loop in Lavish. Show the plan, questions and options as a Lavish artifact, give the session link, and collect answers with `lavish-axi poll`. Keep one artifact file per topic for the whole loop (for example `.lavish/<topic>.html`): each new round or revision edits that same file, Lavish live-reloads it in the open session, and you announce the round with `lavish-axi poll <file> --agent-reply "…"`. Same file, same link. Start a new file only for a new topic. Repo skills still decide what to ask and in what order; Lavish is the surface. The printed session link opens on the user's machine as it is. When `SKILL_LOCKER_LINK_NOTE` is set in `~/.config/skill-locker/local.env`, include that note with the link.

Style every Lavish artifact with the user's house style, `~/.agents/lavish/paper.css` (light paper, serif, dark-red accent). This is the user's named look, so it replaces the Lavish CDN fallback; only an artifact that mocks an app's own UI uses that app's design system. Copy `paper.css` into the artifact's folder and link it as `href="paper.css"`. Before writing a page, read `~/.agents/lavish/GUIDE.md`: visual first, little prose, page structure by mode (plan, as-built, grill round), and the block reference; `example.html` beside it is a working sample.

# implement-spec uses sol-loop

When you run the `implement-spec` skill (repo or personal copy), replace its final review step: on the integration branch, load the `sol-loop` skill instead of `code-review`, and run it against the integration branch base. Fix the findings in a single implementer subagent, as the skill says. All other steps stay as the skill says.
