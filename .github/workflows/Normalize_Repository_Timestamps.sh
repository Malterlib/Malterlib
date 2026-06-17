#!/usr/bin/env bash
set -euo pipefail

RootDir="${1:-$PWD}"
RootDir="$(cd "$RootDir" && pwd)"
ScriptPath="${MALTERLIB_TIMESTAMP_REPO_SCRIPT:-$RootDir/.github/workflows/Normalize_Repository_File_Timestamps.sh}"

if [[ ! -f "$ScriptPath" ]]; then
	echo "Missing per-repository timestamp normalizer: $ScriptPath" >&2
	exit 1
fi

fg_ResolveMergeBaseRef()
{
	local Ref

	Ref="${MALTERLIB_TIMESTAMP_MERGE_BASE_REF:-}"
	if [[ -n "$Ref" ]]; then
		echo "$Ref"
		return 0
	fi

	Ref="$(git -C "$RootDir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
	if [[ -n "$Ref" ]]; then
		echo "$Ref"
		return 0
	fi

	if git -C "$RootDir" remote get-url origin >/dev/null 2>&1; then
		git -C "$RootDir" remote set-head origin --auto >/dev/null 2>&1 || true
	fi

	Ref="$(git -C "$RootDir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
	if [[ -n "$Ref" ]]; then
		echo "$Ref"
		return 0
	fi

	for Ref in origin/master origin/main; do
		if git -C "$RootDir" rev-parse --verify --quiet "$Ref^{commit}" >/dev/null; then
			echo "$Ref"
			return 0
		fi
	done

	return 1
}

fg_FetchRefIfMissing()
{
	local Ref="$1"
	local Remote
	local Branch

	if git -C "$RootDir" rev-parse --verify --quiet "$Ref^{commit}" >/dev/null; then
		return 0
	fi

	case "$Ref" in
		*/*)
			Remote="${Ref%%/*}"
			Branch="${Ref#*/}"
			;;
		*)
			return 0
			;;
	esac

	if git -C "$RootDir" remote get-url "$Remote" >/dev/null 2>&1; then
		git -C "$RootDir" fetch --no-tags "$Remote" "+refs/heads/$Branch:refs/remotes/$Remote/$Branch" >/dev/null
	fi
}

MergeBaseRef="$(fg_ResolveMergeBaseRef)" ||
{
	echo "Unable to resolve the main repository merge-base ref. Set MALTERLIB_TIMESTAMP_MERGE_BASE_REF to override it." >&2
	exit 1
}

fg_FetchRefIfMissing "$MergeBaseRef"

MergeBaseCommit="$(git -C "$RootDir" merge-base HEAD "$MergeBaseRef" 2>/dev/null || true)"
if [[ -z "$MergeBaseCommit" && "$(git -C "$RootDir" rev-parse --is-shallow-repository 2>/dev/null || echo false)" == "true" ]]; then
	UnshallowRemote="${MergeBaseRef%%/*}"
	if [[ "$UnshallowRemote" == "$MergeBaseRef" ]]; then
		UnshallowRemote=origin
	fi

	git -C "$RootDir" fetch --no-tags --unshallow "$UnshallowRemote" >/dev/null 2>&1 || true
	MergeBaseCommit="$(git -C "$RootDir" merge-base HEAD "$MergeBaseRef" 2>/dev/null || true)"
fi
if [[ -z "$MergeBaseCommit" ]]; then
	echo "Unable to find a merge base between HEAD and $MergeBaseRef in $RootDir." >&2
	exit 1
fi

MergeBaseEpoch="$(git -C "$RootDir" show -s --format=%ct "$MergeBaseCommit")"
MergeBaseIso="$(git -C "$RootDir" show -s --format=%cI "$MergeBaseCommit")"

export MALTERLIB_TIMESTAMP_CUTOFF_EPOCH="$MergeBaseEpoch"
export MALTERLIB_TIMESTAMP_CUTOFF_DESCRIPTION="main repository merge base $MergeBaseCommit ($MergeBaseIso) against $MergeBaseRef"
export MALTERLIB_TIMESTAMP_CUTOFF_LABEL="main repository merge-base cutoff"

echo "Normalizing tracked file timestamps using cutoff: $MALTERLIB_TIMESTAMP_CUTOFF_DESCRIPTION."
(
	cd "$RootDir"
	./mib repo-run --skip-update --sync --no-color --no-color-24bit -- bash "$ScriptPath"
)
