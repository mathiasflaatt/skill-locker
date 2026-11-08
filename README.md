# skill-locker

My user skills for coding agents (GitHub Copilot CLI, Claude Code), synced across machines.

Most skills are by other authors (Matt Pocock, Theo Browne, Paul Bakaus and others). See [CREDITS.md](CREDITS.md) for each source and license. Get them from their upstream repos; this repo is my personal copy.

```
shared/<skill>/            skills for every machine
machines/<id>/<skill>/     skills for one machine
machines/<id>/extras       extras that this machine uses, one $HOME-relative path per line
extras/<path>              other agent files, stored at their path under $HOME
bin/skill-locker           sync CLI
```

`<id>` is the machine folder id, not the hostname. See [Machine id](#machine-id).

`bin/skill-locker link` makes these symlinks:

```
~/.agents/skills/<skill>  -> <repo>/shared/<skill>  (or machines/<id>/<skill>)
~/.claude/skills/<skill>  -> ~/.agents/skills/<skill>
```

If a skill is in both `shared/` and `machines/<id>/`, that machine uses its own copy. The `skill-locker` skill tells agents to pull before they edit skills and to push after.

## Extras

Extras are agent files that are not skills. A machine uses an extra only when the path is in its `machines/<id>/extras` list. Then `link` makes `~/<path> -> <repo>/extras/<path>`.

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

Names of private repos, hosts and users stay out of the repo, in `~/.config/skill-locker/local.env` (not synced, mode `0600`). The salt lives only in that file. Do not put the salt, or a map from an id to a hostname, in the repo, a commit, a pull request, a log, or a test.

```bash
# Per-user secret. `skill-locker setup` writes this once. Copy the same value
# to each of your machines through a private channel. Never commit it.
# SKILL_LOCKER_SALT is not shown here on purpose.

# Optional. Selects the machine folder id and wins over the derived id.
# SKILL_LOCKER_MACHINE=

# Optional. Replaces `hostname -s` as the name that is hashed. It does not
# select the folder by itself. `SKILL_LOCKER_MACHINE` does that.
# SKILL_LOCKER_HOSTNAME=

# Repos where agents must not merge into the base branch: "owner/repo:branch" pairs.
SKILL_LOCKER_PROTECTED_REPOS="my-org/my-repo:main"
# SSH target that the user's own machine uses to reach this machine.
SKILL_LOCKER_SSH_TARGET="me@my-host"
# Staging directory for browser artifacts, and an optional note (for example
# how long that directory keeps files).
# SKILL_LOCKER_ARTIFACT_DIR="/path/to/staging"
# SKILL_LOCKER_ARTIFACT_NOTE=
# Optional note included with a Lavish session link.
# SKILL_LOCKER_LINK_NOTE=
# Optional positive integer. Cap on concurrent Aspire runs. Unset means no cap.
# SKILL_LOCKER_ASPIRE_MAX=
# Optional note for finding ports of a local service.
# SKILL_LOCKER_SERVICE_NOTE=
```

The `no-main-merge` hook does nothing when `SKILL_LOCKER_PROTECTED_REPOS` is empty. Machine skills read `SKILL_LOCKER_SSH_TARGET`, `SKILL_LOCKER_ARTIFACT_DIR`, `SKILL_LOCKER_ARTIFACT_NOTE`, and `SKILL_LOCKER_SERVICE_NOTE`. `AGENTS.md` reads `SKILL_LOCKER_LINK_NOTE` and `SKILL_LOCKER_ASPIRE_MAX`. The CLI reads only `SKILL_LOCKER_SALT`, `SKILL_LOCKER_MACHINE`, and `SKILL_LOCKER_HOSTNAME` from the file, and a value already set in the environment wins for those three.

## Machine id

The folder id is the first 12 lowercase hex characters of SHA256(salt concatenated with the short hostname). The salt and the hostname are UTF-8. They are joined with no separator. The hostname is `hostname -s` with the trailing newline removed, unless `SKILL_LOCKER_HOSTNAME` is set. The hash is not computed when the salt is missing. An unsalted hostname is not an id.

`skill-locker` chooses the folder in this order:

1. `SKILL_LOCKER_MACHINE`, when it is set.
2. The derived id, when the salt is set and `machines/<id>/` exists.
3. A legacy folder named with the short hostname, when that folder exists.
4. The derived id, when the salt is set and there is no legacy folder.
5. Otherwise the command fails.

`SKILL_LOCKER_MACHINE` keeps its old role: it overrides the derived id. A legacy folder keeps existing machines working until `migrate` runs. `setup` on a machine that still has a legacy folder does not create an empty derived folder, so the legacy skills stay in use.

`setup` is safe to run again. It does not replace a salt, it does not print the salt, and it does not delete skills or extras. `migrate` renames the legacy folder to the derived id and keeps the files. A second `migrate` does nothing. `migrate` refuses to run without a salt, and it refuses to merge two folders. It hashes the short hostname, or the name given to `--from`, not `SKILL_LOCKER_MACHINE`.

The salt is per user. Use the same salt on every machine. `setup` generates one only when the local env file does not already have one. Put an existing salt in the file before `setup` when this user already has one.

A public commit that renames a legacy hostname folder to a derived id is the mapping. Do not publish that rename as an ordinary commit. Existing legacy folders in this repo are not renamed here. Renaming them needs the private salt and the derived ids held by Ops. This repository does not contain those ids.

`bash tests/skill-locker.sh` checks the id, the override order, opt-in extras, and migrate. It uses a fake salt in a temporary repo.

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
3. Create the salt and the machine folder, outside any shell trace of the salt: `bin/skill-locker setup`.
   Then opt in to the [extras](#extras) you want, for example `bin/skill-locker use .agents/lavish`.
4. Link the skills: `bin/skill-locker pull`. A real folder that blocks a link moves to `~/.skill-locker-backup/<timestamp>/`.
5. Optional: put `bin/` on your `PATH`.

On a machine that already has a legacy folder, run `bin/skill-locker setup`, then `bin/skill-locker migrate`. Do not commit that rename until the private mapping can stay private.

## Daily use

| Command | Effect |
|---|---|
| `skill-locker setup` | Store a salt in the local env file when missing, and create a machine folder for a new machine. |
| `skill-locker migrate [--from <legacy-name>]` | Rename the legacy folder to the derived id. |
| `skill-locker machine-id [--derived]` | Print the folder id. `--derived` fails when the salt is unset. |
| `skill-locker pull` | Pull the latest skills and link them. |
| `skill-locker push "feat: add x skill"` | Commit all changes, rebase, push, link. |
| `skill-locker adopt <name> [--machine]` | Move a local skill folder into the repo. |
| `skill-locker track <path>` | Move a file or folder under `$HOME` into `extras/` and use it on this machine. |
| `skill-locker use <path>` | Use an extra from the repo on this machine. |
| `skill-locker status` | Show repo changes and local skills that the repo does not manage. |
| `skill-locker link` | Make the links again. Removes links to skills that are gone. |

Set `SKILL_LOCKER_MACHINE` to select a folder id. That selection wins over the derived id.
