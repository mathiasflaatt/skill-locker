# Images and video in a PR

`gh` uploads local media itself with `--attach` on `gh pr create`, `gh pr edit`, `gh pr comment` and the same `gh issue` commands. The file goes to GitHub user attachments (`https://github.com/user-attachments/assets/...`), which renders in private repos too. Local paths, `blob/...?raw=true` links and media branches do not count as attached.

## Check first

- `gh` 2.99.0 or later: `printf '%s\n%s\n' 2.99.0 "$(gh --version | sed -n '1s/^gh version \([0-9.]*\).*/\1/p')" | sort -V -C`. Older: use the fallback below.
- The credential is an OAuth token or a personal access token (classic or fine-grained). A GitHub App token fails with `unsupported authentication type`; the fallback fails the same way.
- GitHub Enterprise Server has no attachment upload. Link the file if it has a reachable URL, else say that it is not attached.
- Only images and video. Link any other file type.

## Attach

Put the values in quoted variables, so a file name never runs as shell:

```bash
FILE='shots/after.png'; ALT='the new Review table'
TARGET='https://github.com/OWNER/REPO/pull/123'; REPO='OWNER/REPO'
```

- **New PR:** `gh pr create ... --attach "$FILE#$ALT"`. `gh pr create` needs the head branch (checkout or `--head`).
- **Open PR, at the end of the body:** `gh pr edit "$TARGET" --repo "$REPO" --attach "$FILE#$ALT"`. It keeps the body and appends the image. If the body already references that path, gh replaces that reference instead; attach a copy under a new name to add a second image.
- **At a set place in the body:** write image markdown with the local path (`![alt](<path>)`) in the body file, and attach the same path. gh replaces the path with the asset URL. The paths resolve from the directory where you run `gh`. `gh pr edit --body-file` replaces the full body, so start from the current one:

```bash
gh pr view "$TARGET" --repo "$REPO" --json body -q .body > pr-body.md || exit 1
# add ![before](./before.png) and ![after](./after.png) where they go
gh pr edit "$TARGET" --repo "$REPO" --body-file pr-body.md --attach ./before.png --attach ./after.png
```

Repeat `--attach` for more files (at most 50, each file once per command).

**Video:** attach it with no reference in the body and no `#alt`. gh appends the bare URL on its own line, and GitHub shows a player. Image markdown on a video shows a broken image.

**Partial failure:** gh updates the PR with the files that uploaded and exits non-zero; stderr names the files that failed. Keep the exit status and stderr (`2>attach.err; rc=$?`) and attach only the failed files again.

## Verify

Read the body back. Each attached file is a `user-attachments/assets/` URL, and no attached local path is left:

```bash
set -o pipefail
BODY="$(gh pr view "$TARGET" --repo "$REPO" --json body -q .body)" || exit 1
[ "$(printf '%s\n' "$BODY" | grep -c 'user-attachments/assets/')" -ge 1 ] || echo "not attached" >&2
printf '%s\n' "$BODY" | grep -qF "$FILE" && echo "$FILE still a local path" >&2
```

For a comment, match the URL that `gh pr comment` printed, not the newest comment.

## Fallback: gh older than 2.99.0 (github.com only)

Upload the raw bytes, then put the URL in the body yourself:

```bash
REPO_ID="$(gh api "repos/$REPO" --hostname github.com --jq .id)" || exit 1
URL="$(curl --fail-with-body -sS -X POST https://uploads.github.com/user-attachments/assets \
  --url-query "name=$(basename -- "$FILE")" --url-query "content_type=image/png" \
  --url-query "repository_id=$REPO_ID" \
  -H 'Content-Type: application/octet-stream' -H 'X-GitHub-Api-Version: 2022-11-28' \
  -H "Authorization: Bearer $(gh auth token --hostname github.com)" \
  --data-binary "@$FILE" | jq -r .url)"
case "$URL" in https://*) ;; *) echo "upload failed: $URL" >&2; exit 1;; esac
BODY="$(gh pr view "$TARGET" --repo "$REPO" --json body -q .body)" || exit 1
printf '%s\n\n![%s](%s)\n' "$BODY" "$ALT" "$URL" | gh pr edit "$TARGET" --repo "$REPO" --body-file -
```

Send raw bytes (no multipart, no base64). Set `content_type` to the real MIME type (`video/mp4` for video). Escape `]` and `\` in the alt text.
