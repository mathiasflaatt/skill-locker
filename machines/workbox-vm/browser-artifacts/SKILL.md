---
name: browser-artifacts
description: On workbox-vm only, use when producing standalone files or folders intended to be opened in a browser, such as HTML reports, prototypes, or exported previews. Move finished artifacts to /dev/shm and provide scp download commands.
---

# Browser artifacts

Deliver browser artifacts from this machine through `/dev/shm`. The user's local
machine reaches this host as `$SKILL_LOCKER_SSH_TARGET` (read it with
`. ~/.config/skill-locker/local.env; echo "$SKILL_LOCKER_SSH_TARGET"`).

1. Check `hostname`. Apply this workflow only when it is `workbox-vm`. On other
   machines, leave artifacts in their normal location and omit the download
   command.
2. Identify the finished, standalone deliverable. Keep project source files in
   place; export a separate artifact when the output is part of a project.
   For output with local CSS, JavaScript, images, or other assets, collect the
   complete deliverable in one folder and use relative links within it.
   Artifacts that require an application server or external files are not
   standalone; explain the requirement rather than present them as ready to open.
3. Choose an unused destination directly under `/dev/shm`, with a descriptive
   name containing only letters, digits, dots, underscores, or hyphens.
   Move only the deliverable file or folder. Use a no-overwrite move, and verify
   that the destination exists and the original deliverable is no longer there.
   If output is already under `/dev/shm`, keep it there and verify its contents.
4. Check that all local assets are present and that the SSH user can read the
   files and traverse the artifact's folders. Surface move, asset, or access
   failures explicitly; protect sensitive content rather than make it public.
5. State the final path and provide the actual download command in a code block
   for the user to run on their local machine. Replace `<ssh-target>` with the
   value of `$SKILL_LOCKER_SSH_TARGET` and the example name with the artifact's
   real name:

   File:

   ```bash
   scp <ssh-target>:/dev/shm/report.html ./report.html
   ```

   Folder:

   ```bash
   scp -r <ssh-target>:/dev/shm/browser-report ./browser-report
   ```

   Note that `/dev/shm` is temporary storage and is cleared on reboot. Suggest the
   command; run it only if the user asks and their local machine is accessible.
