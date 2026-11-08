---
name: browser-artifacts
description: Use when producing standalone files or folders intended to be opened in a browser, such as HTML reports, prototypes, or exported previews. Stage finished artifacts and provide scp download commands. Applies only on the machine that links this skill.
---

# Browser artifacts

Deliver browser artifacts through the staging directory in `$SKILL_LOCKER_ARTIFACT_DIR`.
The user's local machine reaches this host as `$SKILL_LOCKER_SSH_TARGET`.
Read both from `~/.config/skill-locker/local.env`. Do not print `SKILL_LOCKER_SALT`.

1. Apply this workflow only when `skill-locker machine-id` prints the same id as the machine folder that contains this skill. On any other machine, leave artifacts in their normal location and omit the download command.
2. Identify the finished, standalone deliverable. Keep project source files in
   place; export a separate artifact when the output is part of a project.
   For output with local CSS, JavaScript, images, or other assets, collect the
   complete deliverable in one folder and use relative links within it.
   Artifacts that require an application server or external files are not
   standalone; explain the requirement rather than present them as ready to open.
3. If `$SKILL_LOCKER_ARTIFACT_DIR` is empty, stop and ask the user to set it in
   the local env file. Choose an unused destination directly under that
   directory, with a descriptive name containing only letters, digits, dots,
   underscores, or hyphens. Move only the deliverable file or folder. Use a
   no-overwrite move, and verify that the destination exists and the original
   deliverable is no longer there. If output is already under that directory,
   keep it there and verify its contents.
4. Check that all local assets are present and that the SSH user can read the
   files and traverse the artifact's folders. Surface move, asset, or access
   failures explicitly; protect sensitive content rather than make it public.
5. State the final path and provide the actual download command in a code block
   for the user to run on their local machine. Replace `<ssh-target>` with the
   value of `$SKILL_LOCKER_SSH_TARGET`, `<staging>` with
   `$SKILL_LOCKER_ARTIFACT_DIR`, and the example name with the artifact's real
   name. When `SKILL_LOCKER_ARTIFACT_NOTE` is set, include that note (it is how
   this machine describes how long staged files are kept).

   File:

   ```bash
   scp <ssh-target>:<staging>/report.html ./report.html
   ```

   Folder:

   ```bash
   scp -r <ssh-target>:<staging>/browser-report ./browser-report
   ```

   Suggest the command; run it only if the user asks and their local machine is accessible.
