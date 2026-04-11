---
name: codex-review
description: Get a second-opinion code review from a different model via the `codex` CLI. Use when the user asks for a code review, second opinion, or sanity check on uncommitted/branch/commit changes before shipping.
---

# Code Review with Codex

Use the `codex` CLI to get a second-opinion review from a different model. Run it from the directory whose changes you want reviewed — `codex review` reads `git diff` relative to its working directory.

When instructing the codex agent don't try to steer it to a specific sort of code review, let it use its default instructions.

```bash
# Review unstaged + staged + untracked changes in the current directory
codex review --uncommitted

# Review changes against a base branch (e.g. before opening a PR)
codex review --base master

# Review a specific commit
codex review --commit <sha>

# Review with a custom prompt (no scope flag — codex picks the diff)
codex review "Review this commit."
```

## CRITICAL — waiting for codex results

**Use the harness's native backgrounding support if it exists.** If the Bash tool exposes `run_in_background: true`, launch `codex review` that way, then immediately return control to the user and STOP. Do NOT issue ANY follow-up tool calls — no `wc`, no `ls`, no `cat`, no `Read`, no `ps`, no `Bash` of any kind. Do not check the output file size. Do not check if the process is running. Do not poll. Do not sleep. Do not "just quickly check". End your message and WAIT. The harness will deliver a background-task-completed notification automatically. Only then may you read the output and continue. Violating this wastes the user's time and context window.

**If the Bash tool does not expose native backgrounding support,** do not try to simulate it with shell backgrounding like `&`. Instead, run `codex review` in the foreground with a timeout large enough to let it finish (or no timeout if the harness allows that), redirect stdout/stderr to a log file, wait for the command result in the same turn, and only then analyze the output by reading the end of that log. In that mode there is no later completion notification to wait for because the command itself should return the finished review.

## Notes

- **Prefer the harness's native background mode when available.** Codex reviews can take minutes for large diffs.
- **When native background mode is unavailable, run `codex review` in the foreground, redirect it to a log file, and increase or disable the timeout so the tool can wait for completion.** Do not append `&` or otherwise detach the process yourself.
- The scope flags `--uncommitted`, `--base`, and `--commit` are **mutually exclusive with the `[PROMPT]` argument**. Passing both fails with `error: the argument '--<flag>' cannot be used with '[PROMPT]'`. Use a scope flag with no prompt, or a prompt with no scope flag — never both.
- `codex review --uncommitted` includes staged + unstaged + untracked. There is no built-in way to scope to *just* unstaged; you'd have to stash the staged changes first, or accept that all three are reviewed.
- Run from inside the relevant sub-repo (e.g. `Malterlib/BuildSystem`) to scope the review and let codex resolve paths correctly.
- Codex output is noisy and large — easily 50–500 KB of exec traces before the actual findings. Prefer redirecting stdout/stderr to a log file (or using the harness's persisted output file when background mode provides one), then inspect only the end of that file to find the final findings block. Do not read the whole transcript unless you need extra context.
- Codex runs read-only and sandboxed — it will not modify files.
