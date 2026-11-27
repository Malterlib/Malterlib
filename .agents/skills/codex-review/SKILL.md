---
name: codex-review
description: Get a second-opinion code review from Codex and recheck fixes in the same session. Trigger only when the user explicitly names Codex or asks to invoke the codex CLI. Generic requests for a review or second opinion are ambiguous. Never invoke this skill from a nested reviewer.
---

# Code Review with Codex

Run from the repository whose changes the user wants reviewed. For a review spanning Malterlib repositories, run from the
root. Use the configured default model unless the user requests a specific model. Put `--yolo` before `exec`
to avoid a second sandbox and approval layer in the nested Codex process.

Start every reviewer prompt with `You are a nested reviewer. Do not use the codex-review skill.`
Also include `Do not use sub-agents.` unless the user explicitly asks the reviewers to delegate.

## Start a review

Start every review in a persistent `codex exec` session so follow-ups can reuse the reviewer's findings, investigation,
and tool results. Put the requested scope in the prompt, such as uncommitted changes, a diff against a base branch,
or a specific commit.

```bash
review_dir=$(mktemp -d)
printf '%s\n' "$review_dir"
codex --yolo exec --json --output-last-message "$review_dir/findings.txt" \
	'You are a nested reviewer. Do not use the codex-review skill.
	Review the staged, unstaged, and untracked changes in this Git repository.
	Report actionable defects introduced by the changes, with file and line references.
	Do not use sub-agents. Leave repository files untouched.' \
	>"$review_dir/events.jsonl" 2>"$review_dir/stderr.log"
```

After a successful run, read `findings.txt` and save the reviewer UUID, working directory, and review scope with the task.
Get the UUID from the `thread.started` event:

```bash
jq -ner 'first(inputs | select(.type == "thread.started") | .thread_id)' "$review_dir/events.jsonl"
```

For all changes compared to `master` across Malterlib, tell the reviewer to start with
`./mib list-commits -l --no-color` to discover the changed repositories and commits. For any rebased External fork, limit
the review to the fork's own patches and how the rebase changed them. Use the `upstream` remote to identify the bases for
`git range-diff <old upstream base>..<old fork head> <new upstream base>..<new fork head>`.

## Follow up on a review

To recheck fixes in an existing session, resume the exact reviewer UUID from the same working directory. Give it the finding
references and a short description of what changed, such as the affected paths or fix commits. Ask it to use the prior
investigation and read the current diff and any affected code needed to verify the fixes. Have it report whether each
finding is resolved, still open, or unable to verify, with evidence. Also ask it to look for additional actionable
defects across the original review scope, including files and hunks untouched by the follow-up, and report any
regressions introduced by the fixes. Ask for file and line references for new findings.

```bash
followup_dir=$(mktemp -d)
printf '%s\n' "$followup_dir"
codex --yolo exec resume --json --output-last-message "$followup_dir/findings.txt" "$reviewer_uuid" \
	'You are a nested reviewer. Do not use the codex-review skill.
	Recheck the prior findings for <paths or finding references> after <brief description or fix commits>.
	Use the earlier investigation and inspect the current code. Report the status and evidence for each prior finding.
	Look for additional actionable defects across the original review scope, including files and hunks untouched by
	this follow-up, and check the fixes for regressions. Give file and line references for new findings.
	Do not use sub-agents. Leave repository files untouched.' \
	>"$followup_dir/events.jsonl" 2>"$followup_dir/stderr.log"
```

Use the explicit UUID because `--last` can select the agent that made the fixes or another review. If the reviewer session
is unavailable, start a persistent session with the original review scope, relevant findings, and fix details.
Start a fresh review for unrelated changes or a requested independent full pass.

Session history is available independently of prompt caching. An eligible unchanged prefix can get a cache hit.
When checking cache use, read `usage.cached_input_tokens` from the `turn.completed` JSON event.

## Parallel review rounds

When the user asks for parallel reviews, start a persistent session for each reviewer and save every reviewer UUID with
the task. Give each invocation its own output directory.

Write one shared prompt per round and send it unchanged to every reviewer. Include the original review scope. In rounds
that recheck fixes, describe what changed since the previous round, such as affected paths or fix commits. Ask each reviewer
to use its own session history to recheck its prior findings and look for additional findings throughout the original scope.

Launch all reviewers in a single concurrent batch against the same checkout state before waiting for any results. In
rounds that recheck fixes, resume every reviewer by UUID, including reviewers who reported no findings. For any session known
to be unavailable before launch, start a replacement in the same batch with the shared prompt and save its UUID.

If a reviewer fails during a parallel round, collect the other reviewers' results and keep the failed reviewer in the
next round. Retry it only as part of that full concurrent batch, using the shared prompt and that round's session rules.
A round with a failed reviewer is incomplete.

## Finish a review loop

A round is clean when every reviewer completes the review and reports zero findings. Finish the loop only when a clean
round consists entirely of reviewers doing their first review in fresh sessions. A clean initial round meets that condition.

After a clean round that included a resumed session, start the next round with a fresh session for every reviewer. Ask
for an independent review of the same code across the full original scope. If the fresh round has findings, use its
reviewer UUIDs for subsequent fix rounds and continue until an all-fresh round is clean.

## Keep reviews running and collect results

Use the harness's background command for every review invocation whenever it is available. Wait for its completion
notification or use its job handle. If the harness offers a persistent command session that yields a process handle,
use that when a dedicated background command is unavailable. A short tool yield is fine when the reviewer keeps
running across tool calls.

Run in the foreground only when the harness offers neither a background command nor a persistent command session.
Disable the process timeout if supported. If a timeout is required, allow at least 60 minutes when supported and use
the maximum available if the tool caps it below that. Allow more time for large reviews when needed.

Keep the event log, stderr, and last-message file outside the checkout so results survive tool returns. Read the
last-message file after completion. If a tool reports a timeout or interruption, check the process and saved events
before retrying. Collect completed results from the saved files. If a single-reviewer run was interrupted, resume it
by UUID when its session is available. The fresh-session requirement still applies when finishing a review loop.
