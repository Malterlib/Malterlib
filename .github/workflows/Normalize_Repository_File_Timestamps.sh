#!/usr/bin/env bash
set -euo pipefail

RepoDir="${1:-$PWD}"
RepoDir="$(cd "$RepoDir" && pwd)"
TouchMode=timestamp
TouchNoDereference=false
TouchJobs="${MALTERLIB_TIMESTAMP_TOUCH_JOBS:-4}"
TouchBatchSize="${MALTERLIB_TIMESTAMP_TOUCH_BATCH_SIZE:-2048}"
TimestampCutoffEpoch="${MALTERLIB_TIMESTAMP_CUTOFF_EPOCH:-}"
TimestampCutoff="${MALTERLIB_TIMESTAMP_CUTOFF:-1 week ago}"
TimestampCutoffDescription="${MALTERLIB_TIMESTAMP_CUTOFF_DESCRIPTION:-$TimestampCutoff}"
TimestampCutoffLabel="${MALTERLIB_TIMESTAMP_CUTOFF_LABEL:-$TimestampCutoffDescription}"
TrackedFiles=""
TimestampMap=""

fg_Cleanup()
{
	if [[ -n "$TrackedFiles" ]]; then
		rm -f "$TrackedFiles"
	fi
	if [[ -n "$TimestampMap" ]]; then
		rm -f "$TimestampMap"
	fi
}

trap fg_Cleanup EXIT

fg_FormatTouchTimestamp()
{
	local Epoch="$1"

	if date -u -d "@$Epoch" +%Y%m%d%H%M.%S >/dev/null 2>&1; then
		date -u -d "@$Epoch" +%Y%m%d%H%M.%S
	else
		date -u -r "$Epoch" +%Y%m%d%H%M.%S
	fi
}

fg_DetectTouchMode()
{
	local Probe

	Probe="$(mktemp)"
	if touch -h "$Probe" >/dev/null 2>&1; then
		TouchNoDereference=true
	fi

	if touch -c -d "@0" "$Probe" >/dev/null 2>&1; then
		TouchMode=epoch
	fi

	rm -f "$Probe"
}

fg_TouchFile()
{
	local Epoch="$1"
	local Path="$2"
	local TouchTimestamp

	if [[ "$TouchMode" == "epoch" ]]; then
		if [[ "$TouchNoDereference" == "true" ]]; then
			touch -c -h -d "@$Epoch" "$Path"
		else
			touch -c -d "@$Epoch" "$Path"
		fi
	else
		TouchTimestamp="$(fg_FormatTouchTimestamp "$Epoch")"
		if [[ "$TouchNoDereference" == "true" ]]; then
			touch -c -h -t "$TouchTimestamp" "$Path"
		else
			touch -c -t "$TouchTimestamp" "$Path"
		fi
	fi
}

fg_TouchFilesToEpoch()
{
	local Epoch="$1"
	local TouchTimestamp

	if [[ "$TouchMode" == "epoch" ]]; then
		if [[ "$TouchNoDereference" == "true" ]]; then
			xargs -0 -n "$TouchBatchSize" -P "$TouchJobs" sh -c '
				Timestamp="$1"
				shift
				if [ "$#" -gt 0 ]; then
					touch -c -h -d "@$Timestamp" "$@"
				fi
			' sh "$Epoch"
		else
			xargs -0 -n "$TouchBatchSize" -P "$TouchJobs" sh -c '
				Timestamp="$1"
				shift
				if [ "$#" -gt 0 ]; then
					touch -c -d "@$Timestamp" "$@"
				fi
			' sh "$Epoch"
		fi
	else
		TouchTimestamp="$(fg_FormatTouchTimestamp "$Epoch")"
		if [[ "$TouchNoDereference" == "true" ]]; then
			xargs -0 -n "$TouchBatchSize" -P "$TouchJobs" sh -c '
				Timestamp="$1"
				shift
				if [ "$#" -gt 0 ]; then
					touch -c -h -t "$Timestamp" "$@"
				fi
			' sh "$TouchTimestamp"
		else
			xargs -0 -n "$TouchBatchSize" -P "$TouchJobs" sh -c '
				Timestamp="$1"
				shift
				if [ "$#" -gt 0 ]; then
					touch -c -t "$Timestamp" "$@"
				fi
			' sh "$TouchTimestamp"
		fi
	fi
}

fg_SelectBaselineCommit()
{
	if [[ -n "$TimestampCutoffEpoch" ]]; then
		git rev-list -1 --before="@$TimestampCutoffEpoch" HEAD || true
	else
		git rev-list -1 --before="$TimestampCutoff" HEAD || true
	fi
}

cd "$RepoDir"

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
	echo "Skipping $RepoDir: repository has no HEAD commit."
	exit 0
fi

if [[ -n "$TimestampCutoffEpoch" && ! "$TimestampCutoffEpoch" =~ ^[0-9]+$ ]]; then
	echo "Invalid MALTERLIB_TIMESTAMP_CUTOFF_EPOCH: $TimestampCutoffEpoch" >&2
	exit 1
fi

fg_DetectTouchMode

TrackedFiles="$(mktemp)"
TimestampMap="$(mktemp)"
git ls-tree -r -z --name-only HEAD > "$TrackedFiles"

TrackedCount="$(tr -cd '\0' < "$TrackedFiles" | wc -c | tr -d '[:space:]')"
if [[ "$TrackedCount" == "0" ]]; then
	echo "No tracked files to timestamp in $RepoDir."
	exit 0
fi

BaselineCommit="$(fg_SelectBaselineCommit)"
if [[ -z "$BaselineCommit" ]]; then
	BaselineCommit="$(git rev-list --max-parents=0 HEAD | tail -n 1)"
fi
BaselineEpoch="$(git show -s --format=%ct "$BaselineCommit")"
BaselineIso="$(git show -s --format=%cI "$BaselineCommit")"
BaselineShort="$(git rev-parse --short=12 "$BaselineCommit")"

echo "Touching $TrackedCount tracked files to baseline commit $BaselineShort ($BaselineIso), selected at or before $TimestampCutoffLabel."
fg_TouchFilesToEpoch "$BaselineEpoch" < "$TrackedFiles"

export TRACKED_FILE="$TrackedFiles"
git log "$BaselineCommit..HEAD" --format='MALTERLIB_TIMESTAMP:%ct' --name-only -z -- |
	perl -0ne '
		BEGIN
		{
			binmode STDOUT;
			$TrackedFile = $ENV{"TRACKED_FILE"};
			open(my $TrackedHandle, "<:raw", $TrackedFile) or die "Unable to open $TrackedFile: $!";
			local $/ = "\0";
			while (defined(my $Path = <$TrackedHandle>))
			{
				chomp $Path;
				$Tracked{$Path} = 1 if $Path ne "";
			}
			close $TrackedHandle;
			$CurrentEpoch = "";
		}

		chomp;
		s/^\n+//;
		if (/^MALTERLIB_TIMESTAMP:(\d+)$/)
		{
			$CurrentEpoch = $1;
			next;
		}

		next if $_ eq "" || $CurrentEpoch eq "" || !exists $Tracked{$_} || exists $EpochByPath{$_};
		$EpochByPath{$_} = $CurrentEpoch;

		END
		{
			for my $Path (keys %EpochByPath)
			{
				print $EpochByPath{$Path}, "\0", $Path, "\0";
			}
		}
	' > "$TimestampMap"

TouchedCount=0
while IFS= read -r -d '' Epoch && IFS= read -r -d '' Path
do
	fg_TouchFile "$Epoch" "$Path"
	((++TouchedCount))
done < "$TimestampMap"

echo "Refined $TouchedCount recently changed tracked files."
