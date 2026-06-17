#!/usr/bin/env bash
set -euo pipefail

: "${PLATFORM:?}"
: "${MINIMUM_AVAILABLE_GB:?}"

fg_SetStatus()
{
	local Status="$1"

	if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
		echo "status=$Status" >> "$GITHUB_OUTPUT"
	fi
}

fg_PrintDiskSpace()
{
	df -h --sync
}

fg_GetBestLinuxBuildMount()
{
	local AvailableKb=0
	local AvailableMount=""
	local Filesystem
	local Blocks
	local Used
	local Available
	local Capacity
	local Mount

	while read -r Filesystem Blocks Used Available Capacity Mount
	do
		if [[ "$Filesystem" == "Filesystem" ]]; then
			continue
		fi

		case "$Filesystem" in
			tmpfs|devtmpfs|efivarfs|overlay)
				continue
				;;
		esac

		case "$Mount" in
			/dev|/dev/*|/proc|/proc/*|/run|/run/*|/sys|/sys/*|/boot|/boot/*)
				continue
				;;
		esac

		if [[ ! "$Available" =~ ^[0-9]+$ ]]; then
			continue
		fi

		if (( Available > AvailableKb )); then
			AvailableKb="$Available"
			AvailableMount="$Mount"
		fi
	done < <(df -Pk --sync)

	printf '%s %s\n' "$AvailableKb" "$AvailableMount"
}

fg_CleanupLinuxRunner()
{
	sudo rm -rf /usr/local/lib/android /usr/share/swift /usr/local/share/powershell /usr/lib/jvm /opt/az /usr/lib/llvm-* /usr/share/miniconda /usr/local/julia* /opt/microsoft/msedge /usr/lib/dotnet /usr/share/az_* /usr/lib/firefox /opt/microsoft/powershell /usr/share/gradle-* /usr/share/kotlinc /opt/ghc /opt/hostedtoolcache/CodeQL || true
}

if [[ "$PLATFORM" != "Linux" ]]; then
	echo "Runner disk preflight is only enforced for Linux."
	fg_SetStatus ok
	exit 0
fi

echo "::group::Runner disk before cleanup"
fg_PrintDiskSpace
echo "::endgroup::"

fg_CleanupLinuxRunner

echo "::group::Runner disk after cleanup"
fg_PrintDiskSpace
echo "::endgroup::"

read -r AvailableKb AvailableMount < <(fg_GetBestLinuxBuildMount)
MinimumKb=$((MINIMUM_AVAILABLE_GB * 1024 * 1024))

if ! [[ "$AvailableKb" =~ ^[0-9]+$ ]]; then
	echo "::error::Unable to determine available disk space on Linux build mounts."
	exit 1
fi

if [[ -z "$AvailableMount" ]]; then
	echo "::warning::No suitable Linux build mount found."
	fg_SetStatus retry
	exit 0
fi

if (( AvailableKb < MinimumKb )); then
	AvailableGb=$((AvailableKb / 1024 / 1024))
	echo "::warning::LOW_DISK_RUNNER_RETRY: rejecting runner with ${AvailableGb} GB available on best build mount $AvailableMount; need at least ${MINIMUM_AVAILABLE_GB} GB."
	fg_SetStatus retry
	exit 0
fi

echo "Runner disk preflight passed: $((AvailableKb / 1024 / 1024)) GB available on best build mount $AvailableMount."
fg_SetStatus ok
