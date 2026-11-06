# Making a Malterlib pull request

A Malterlib change usually spans several repositories: the root `Malterlib/Malterlib` repository and the
sub-repositories under `Malterlib/` and `External/` that it pins in its `.MRepo` files. This document describes how to
prepare such a change, open its pull requests, get it reviewed and land it.

## 1. Branch

Create a branch in the root and every sub-repository at once:

```bash
./mib branch <name>
```

For card work, use the card's branch name, such as `mal-<N>-<slug>`. `./mib unbranch` goes back to each repository's
default branch: `master`, or `malterlib` for `External` forks.

## 2. Commits

- Commits are atomic and coherent: one logical change per commit, and each logical change in one commit.
- A later commit doesn't change the behavior of an earlier one. If it would, the change belongs in the earlier commit.
- Write messages in the repository's style.
- Don't add `Co-Authored-By:`, `Generated with ...`, `Claude-Session:` or other attribution trailers.

## 3. Binaries

Only members of a binary repository's push team change binary repositories. No other repository takes compiled
binaries (executables, libraries, object files and the like); scripts are fine.

Don't set `working-tree-encoding` in a `.gitattributes`, or mention it there at all: checkout would write other bytes
than the ones committed, so the review bot refuses it.

Don't let checkout convert binary files (any file with a NUL byte) either. The review bot refuses one whose
`.gitattributes` attributes set `ident` or `text`, set `crlf` while `text` isn't unset (`-text`), or set `eol=crlf`
while `text` is neither `auto` nor unset, also when the attributes come from a pattern such as `*`. `eol=crlf` on text files is fine.
It checks every version of a file that your commits bring, and the files of every commit that changes a
`.gitattributes`. A binary file the default branch already has unchanged at that path, converted there exactly the
same way (the same `ident`, `text`, `crlf` and `eol` values), isn't refused, and neither is one an External fork's
upstream has at that path with that mode, when upstream's attributes convert it exactly the same way too.

## 4. Update repositories

After committing in sub-repositories, run this from the root:

```bash
./mib repo-commit
```

It creates the `Update repositories` commits in each parent up to the root, with messages listing the child commits.
These commits contain only `.MRepo` files; never edit them by hand or put other changes in them. When everything is
committed, running `./mib repo-commit` again changes nothing.

Only one commit of a change may move a given pin, which is what `./mib repo-commit` produces.

## 5. Not ready for CI yet

Use `./mib repo-commit --skip-ci`, which adds `[skip ci]` to the root commit. Run it again without `--skip-ci` once the
change is ready; a change with `[skip ci]` isn't pushed.

## 6. Push

Push your branch in every repository with:

```bash
./mib push
```

## 7. Sub-repository pull requests

Open a pull request in every sub-repository, `External` forks included, that has commits other than
`Update repositories` commits, against its default branch. A repository whose only commits are `Update repositories`
commits, usually `Malterlib/Core`, needs no pull request. An `External` fork that only moves on to newer upstream
commits, with no commits of its own, still needs one, since those commits aren't on its default branch yet.

## 8. Main pull request

Open the main pull request in `Malterlib/Malterlib` last. Its description links every sub-repository pull request,
with the full URL, one per line, and says what the change does. The commits it brings in are in its
`Update repositories` commit, so no `./mib list-commits` output is needed.

A sub-repository pull request that no main pull request links gets a comment with these instructions after a while.

## 9. External forks

To update a fork to a newer upstream, rebase the fork's commits onto the upstream branch on your feature branch (the
one `./mib branch` created, which `mib` keeps every repository on). Keep the fork's own commits clean and atomic: forks
only take rebases and cherry-picks, never merges of their own. Push it with `./mib push --force` and open a pull request
for it like any other repository. The fork's `malterlib` branch itself only moves when the change lands. The review
covers the fork's commits and how the rebase changed them.

## 10. Review

A member of the Pushers team submits a pull request review on the main pull request whose text is
`@malterlib-review-bot review`. The review bot first checks the change for malicious content, then builds and reviews
it, and posts findings on the pull request of the repository they are in, with a summary on the main pull request.
Reply to a finding you disagree with; a Pushers member decides.

## 11. Fixing review findings

Fold each fix into the commit it belongs to, not into a new "fix review" commit:

```bash
git commit --fixup=<sha>
git rebase -i --autosquash <base>
```

A fix that is a change of its own is a new commit. Then run `./mib repo-commit` and `./mib push --force`. History stays
clean: every commit as it should land.

## 12. Rebasing

When a default branch moved, rebase the root and the changed sub-repositories, run `./mib repo-commit` and
`./mib push --force` on your branch, and ask for a new round. The bot still reviews a change that is behind,
against its merge base, but it can't be ready or pushed until it is rebased.

## 13. Landing

Don't use the merge button. CI has to have run; the bot judges its failures. A Pushers member approves the main pull
request once the bot reports it ready, and the bot pushes the default branch of every repository to the reviewed
commits, which closes all the pull requests of the change.
