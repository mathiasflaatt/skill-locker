---
name: share-local-service
description: On workbox-vm only, use when sharing a running server with the user — Aspire dashboard, dev server, API, preview, or any localhost URL. Give an SSH port-forward command for their local machine and the forwarded link.
---

# Share a local service

The user's local machine reaches this host over Tailscale as
`$SKILL_LOCKER_SSH_TARGET` (read it with
`. ~/.config/skill-locker/local.env; echo "$SKILL_LOCKER_SSH_TARGET"`). Share running services through an SSH port-forward on the **same port
number**, so URLs printed by tools (such as the Aspire dashboard login link with
its token) open unchanged on the user's machine.

1. Check `hostname`. Apply this workflow only when it is `workbox-vm`. On other
   machines, give the URL as it is.
2. Find each port the user needs, from the tool's output (for example the URL
   that `aspire start` prints) or `aspire describe <resource>`. Ports are
   random per run, so read them from the current run.
3. Verify each port is listening with `ss -ltn`. Note the bind address: for
   `127.0.0.1`, `0.0.0.0`, or `*`, forward to `localhost`; for a specific
   address, forward to that address.
4. Give one command in a code block for the user to run on their local machine,
   with one `-L` per port, and `<ssh-target>` replaced by the value of
   `$SKILL_LOCKER_SSH_TARGET`:

   ```bash
   ssh -N -L 17123:localhost:17123 -L 5173:localhost:5173 <ssh-target>
   ```

5. Give the full link to open on their machine, including path, query, and
   scheme exactly as the service prints them, for example
   `https://localhost:17123/login?t=<token>`. Say that the tunnel stays open
   until they press Ctrl-C, and that if a local port is in use they can change
   only the first number of that `-L` and the link's port to match.
