---
name: share-local-service
description: Use when sharing a running server with the user, such as a dashboard, dev server, API, preview, or any localhost URL. Give an SSH port-forward command for their local machine and the forwarded link. Applies only on the machine that links this skill.
---

# Share a local service

The user's local machine reaches this host as `$SKILL_LOCKER_SSH_TARGET`
(read `~/.config/skill-locker/local.env`; do not print `SKILL_LOCKER_SALT`).
Share running services through an SSH port-forward on the **same port
number**, so URLs printed by tools (including a login link with its token)
open unchanged on the user's machine.

1. Apply this workflow only when `skill-locker machine-id` prints the same id
   as the machine folder that contains this skill. On any other machine, give
   the URL as it is.
2. Find each port the user needs from the tool's current output. Ports often
   change per run, so read them from the current run. When
   `SKILL_LOCKER_SERVICE_NOTE` is set in the local env file, follow that note
   when locating ports.
3. Verify each port is listening with `ss -ltn`. Note the bind address: for
   `127.0.0.1`, `0.0.0.0`, or `*`, forward to `localhost`; for a specific
   address, forward to that address.
4. Give one command in a code block for the user to run on their local machine,
   with one `-L` per port, and `<ssh-target>` replaced by the value of
   `$SKILL_LOCKER_SSH_TARGET`:

   ```bash
   ssh -N -L 8080:localhost:8080 -L 5173:localhost:5173 <ssh-target>
   ```

5. Give the full link to open on their machine, including path, query, and
   scheme exactly as the service prints them, for example
   `https://localhost:8080/login?t=<token>`. Say that the tunnel stays open
   until they press Ctrl-C, and that if a local port is in use they can change
   only the first number of that `-L` and the link's port to match.
