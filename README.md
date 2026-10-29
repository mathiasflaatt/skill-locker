# skill-locker

My user skills for coding agents (GitHub Copilot CLI, Claude Code), synced across machines.

Most skills are by other authors (Matt Pocock, Theo Browne, Paul Bakaus and others). See [CREDITS.md](CREDITS.md) for each source and license. Get them from their upstream repos; this repo is my personal copy.

```
shared/<skill>/            skills for every machine
machines/<host>/<skill>/   skills for one machine (host = `hostname -s`)
machines/<host>/extras     extras that this machine uses, one $HOME-relative path per line
extras/<path>              other agent files, stored at their path under $HOME
bin/skill-locker           sync CLI
```

`bin/skill-locker link` makes these symlinks:

```
~/.agents/skills/<skill>  -> <repo>/shared/<skill>  (or machines/<host>/<skill>)
~/.claude/skills/<skill>  -> ~/.agents/skills/<skill>
```

If a skill is in both `shared/` and `machines/<host>/`, that machine uses its own copy. The `skill-locker` skill tells agents to pull before they edit skills and to push after.

## Extras

Extras are agent files that are not skills. A machine uses an extra only when the path is in its `machines/<host>/extras` list. Then `link` makes `~/<path> -> <repo>/extras/<path>`.

| Extra | Purpose |
|---|---|
| `.agents/AGENTS.md` | Personal agent instructions. |
| `.agents/hooks/` | Hook scripts. |
| `.agents/lavish/` | Lavish house style (`paper.css`, `GUIDE.md`, `example.html`). |
| `.copilot/hooks/no-main-merge.json` | Copilot registration for the `no-main-merge` hook. |
| `.copilot/agents/designer.agent.md` | `designer` custom agent (Copilot). |
| `.claude/agents/designer.agent.md` | The same agent for Claude Code (a link in the repo to the Copilot file). |
| `.agents/agent-skills/designer/` | Private skills for `designer`: [impeccable](https://github.com/pbakaus/impeccable), Apache-2.0. |

### Agent-only skills

A skill that only one custom agent uses goes in `extras/.agents/agent-skills/<agent>/<skill>/`. No agent scans that folder, so the skill stays out of the default skill list. The agent file tells the agent to read the skill's `SKILL.md` by path. impeccable downloads its engine to `~/.impeccable/` on first run.

Each agent reads `AGENTS.md` through a per-machine link, so make these links on a new machine:

```bash
ln -s ../.agents/AGENTS.md ~/.claude/CLAUDE.md
ln -s ../.agents/AGENTS.md ~/.copilot/copilot-instructions.md
```

Claude Code registers hooks in `~/.claude/settings.json`, which is not synced. Add the hook entry by hand on each machine, with the absolute path to `~/.agents/hooks/no-main-merge.sh`.

### Local settings

Names of private repos, hosts and users stay out of the repo, in `~/.config/skill-locker/local.env` (not synced):

```bash
# Repos where agents must not merge into the base branch: "owner/repo:branch" pairs.
SKILL_LOCKER_PROTECTED_REPOS="my-org/my-repo:main"
# SSH target that the user's own machine uses to reach this machine.
SKILL_LOCKER_SSH_TARGET="me@my-host"
```

The `no-main-merge` hook does nothing when `SKILL_LOCKER_PROTECTED_REPOS` is empty. Machine skills read `SKILL_LOCKER_SSH_TARGET`.

If you remove a path from a machine's `extras` list, `link` removes the link. It does not restore the backup.

## Set up a new machine

1. Make a fine-grained PAT with access to this repo only (Contents: read and write).
2. Clone and store the token for this repo only:

   ```bash
   git clone https://github.com/mathiasflaatt/skill-locker.git ~/skill-locker
   cd ~/skill-locker
   mkdir -p ~/.config/skill-locker && umask 077
   read -rsp 'Token: ' T && echo "https://mathiasflaatt:$T@github.com" > ~/.config/skill-locker/credentials && unset T
   git config credential.https://github.com.helper ""
   git config --add credential.https://github.com.helper "store --file ~/.config/skill-locker/credentials"
   ```

   The empty `helper ""` stops this repo from using a global helper (for example `gh`).
3. Link the skills: `bin/skill-locker pull`. A real folder that blocks a link moves to `~/.skill-locker-backup/<timestamp>/`.
   Then opt in to the [extras](#extras) you want, for example `bin/skill-locker use .agents/lavish`.
4. Optional: put `bin/` on your `PATH`.

## Daily use

| Command | Effect |
|---|---|
| `skill-locker pull` | Pull the latest skills and link them. |
| `skill-locker push "feat: add x skill"` | Commit all changes, rebase, push, link. |
| `skill-locker adopt <name> [--machine]` | Move a local skill folder into the repo. |
| `skill-locker track <path>` | Move a file or folder under `$HOME` into `extras/` and use it on this machine. |
| `skill-locker use <path>` | Use an extra from the repo on this machine. |
| `skill-locker status` | Show repo changes and local skills that the repo does not manage. |
| `skill-locker link` | Make the links again. Removes links to skills that are gone. |

Set `SKILL_LOCKER_MACHINE` to use a different machine name.
