---
name: skill-locker
description: Sync user skills and personal agent files through the skill-locker repo. Use when you create, edit, rename or delete a user skill (in ~/.agents/skills, ~/.claude/skills or ~/.copilot/skills), edit ~/.agents/AGENTS.md, a personal hook or ~/.agents/lavish, or when the user asks to sync, pull or push skills.
---

# skill-locker

User skills live in the skill-locker git repo. `~/.agents/skills/<name>` is a symlink into the repo, and `~/.claude/skills/<name>` is a symlink to that. An edit made through either path is an edit to the repo.

- `shared/<name>/` holds skills for every machine.
- `machines/<id>/<name>/` holds skills for one machine. `<id>` is the first 12 lowercase hex characters of SHA256(per-user salt concatenated with `hostname -s`), or `SKILL_LOCKER_MACHINE` when that variable is set. If the same name is in both `shared/` and `machines/<id>/`, this machine uses its own copy.
- `extras/<path>` holds other agent files (`AGENTS.md`, hooks, Lavish style), linked to `~/<path>`. A machine uses only the extras listed in `machines/<id>/extras`.

Run the CLI through the skill's own link, so any clone location works:

```bash
SL="$(readlink -f ~/.agents/skills/skill-locker)/../../bin/skill-locker"
"$SL" status
```

## Steps

1. **Pull first.** Before you edit or create a skill, run `"$SL" pull`.
2. **Place the skill.**
   - To edit a skill, edit it in place. The symlink takes the change to the repo.
   - To create a skill, write it in `shared/<name>/` in the repo. If it only works on this machine (it uses local paths, hosts or services), write it in `machines/<id>/<name>/`. If the scope is not clear, ask the user. Read host names, user names, and other machine-specific values from `~/.config/skill-locker/local.env`. Do not write them into the skill.
   - To take in a skill that exists only as a local folder, run `"$SL" adopt <name>` (add `--machine` for a machine skill).
   - To delete or rename a skill, use `git mv` or `git rm` in the repo.
   - To sync a new agent file under `$HOME`, run `"$SL" track <path>`. To use a synced extra on this machine, run `"$SL" use <path>`.
   - To give a skill to one custom agent only, put it in `extras/.agents/agent-skills/<agent>/<skill>/` and make the agent file read it by path. This keeps it out of the default skill list.
3. **Push.** Run `"$SL" push "<conventional commit message>"`, for example `feat: add tdd skill`. This commits, rebases on the remote, pushes and links again.

The work is done when `"$SL" status` shows a clean branch that is level with `origin`, and lists no local skills outside the repo.

## Gotchas

- `push` and `pull` back up a real folder that blocks a link to `~/.skill-locker-backup/<timestamp>/`. They do not delete it.
- Plugin skills (from `/plugin`) and repo skills (`.claude/skills` in a project) are not user skills. Leave them out of the locker.
- This repo is public: keep secrets, tokens, customer data and names of private repos, hosts or users out of it. Put machine-specific names in `~/.config/skill-locker/local.env` (see the README). Never print `SKILL_LOCKER_SALT`. Never commit that file, a salt, or a table that maps a machine id to a hostname.
- A commit that renames a legacy hostname folder to a derived id publishes the mapping. Do not push that rename as an ordinary commit.
- On a new machine, run `"$SL" setup` before the first link. `setup` is idempotent and does not replace an existing salt. To move an existing legacy folder, run `"$SL" migrate` after the salt is in the local env file.
- When you copy a skill from another author, keep its `LICENSE` in the skill folder and add a row to `CREDITS.md`.
