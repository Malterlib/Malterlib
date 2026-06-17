#!/usr/bin/env bash
set -euo pipefail

: "${PLATFORM:?}"
: "${ARCH:?}"
: "${LLVM_STAGE:?}"

BUILD_IN_CONTAINER="${BUILD_IN_CONTAINER:-false}"
MALTERLIB_RUNNING_IN_CONTAINER="${MALTERLIB_RUNNING_IN_CONTAINER:-false}"
RESTORE_BUILD_STATE="${RESTORE_BUILD_STATE:-false}"
ARCHIVE_BUILD_STATE="${ARCHIVE_BUILD_STATE:-false}"
CREATE_DISTRIBUTION_ARCHIVE="${CREATE_DISTRIBUTION_ARCHIVE:-false}"
LLVM_PARALLEL_LINK_JOBS="${LLVM_PARALLEL_LINK_JOBS:-1}"
export LLVM_PARALLEL_LINK_JOBS

fg_PrintSafeEnv()
{
	env | sort | sed -E 's/^([^=]*(TOKEN|PASSWORD|SECRET|KEY|CREDENTIAL|AUTH)[^=]*=).*/\1<masked>/I'
}

fg_StageStatusFile()
{
	mkdir -p BuildStates
	echo "$PWD/BuildStates/MalterlibLLVMBuild-$PLATFORM-$ARCH-$LLVM_STAGE.status"
}

fg_SetStageStatus()
{
	local Status="$1"
	local StatusFile

	StatusFile="$(fg_StageStatusFile)"
	echo "$Status" > "$StatusFile"

	if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
		echo "status=$Status" >> "$GITHUB_OUTPUT"
	fi
}

fg_EmitStageStatusFromFile()
{
	local StatusFile
	local Status

	StatusFile="$(fg_StageStatusFile)"
	if [[ ! -f "$StatusFile" || -z "${GITHUB_OUTPUT:-}" ]]; then
		return 0
	fi

	Status="$(cat "$StatusFile")"
	if [[ -n "$Status" ]]; then
		echo "status=$Status" >> "$GITHUB_OUTPUT"
	fi
}

fg_FreeLinuxDiskSpace()
{
	df -h
	sudo rm -rf /usr/local/lib/android /usr/share/swift /usr/local/share/powershell /usr/lib/jvm /opt/az /usr/lib/llvm-* /usr/share/miniconda /usr/local/julia* /opt/microsoft/msedge /usr/lib/dotnet /usr/share/az_* /usr/lib/firefox /opt/microsoft/powershell /usr/share/gradle-* /usr/share/kotlinc /opt/ghc /opt/hostedtoolcache/CodeQL || true
	sudo apt-get update
	sudo apt-get install -y zstd
	df -h
}

fg_ReportLinuxMemoryAndSwap()
{
	echo "Memory and swap:"
	df -h
	free -h
	echo
	swapon --show
	echo
}

fg_SetLinuxSwap()
{
	local SwapFile
	local ExtraSwapFile

	echo "::group::Swap space report before modification"
	fg_ReportLinuxMemoryAndSwap
	echo "::endgroup::"

	SwapFile="$(swapon --show=NAME | tail -n 1 || true)"
	if [[ -z "$SwapFile" ]]; then
		SwapFile="/swapfile"
	fi

	sudo swapoff "$SwapFile" 2>/dev/null || true
	sudo rm -f "$SwapFile"
	sudo fallocate -l 12G "$SwapFile"
	sudo chmod 600 "$SwapFile"
	sudo mkswap "$SwapFile"
	sudo swapon "$SwapFile"

	ExtraSwapFile="/extra.swap"
	sudo swapoff "$ExtraSwapFile" 2>/dev/null || true
	sudo rm -f "$ExtraSwapFile"
	sudo fallocate -l 8G "$ExtraSwapFile"
	sudo chmod 600 "$ExtraSwapFile"
	sudo mkswap "$ExtraSwapFile"
	sudo swapon "$ExtraSwapFile"

	echo "::group::Swap space report after modification"
	fg_ReportLinuxMemoryAndSwap
	echo "::endgroup::"
}

fg_FreeMacOSDiskSpace()
{
	df -h

	local ActiveXcode=""
	local DeveloperDir
	DeveloperDir="$(xcode-select -p 2>/dev/null || true)"
	if [[ "$DeveloperDir" == /Applications/*.app/Contents/Developer ]]; then
		ActiveXcode="${DeveloperDir%/Contents/Developer}"
	fi

	local XcodeApp
	for XcodeApp in /Applications/Xcode*.app; do
		if [[ ! -e "$XcodeApp" || "$XcodeApp" == "$ActiveXcode" ]]; then
			continue
		fi

		sudo rm -rf "$XcodeApp"
	done

	sudo rm -rfx \
		"$HOME/Library/Developer/CoreSimulator" \
		"$HOME/Library/Developer/Xcode/DerivedData" \
		"/Library/Developer/CoreSimulator" \
		"/Library/Developer/Xcode/iOS DeviceSupport" \
		"/Library/Developer/Xcode/watchOS DeviceSupport" \
		"/Library/Developer/Xcode/tvOS DeviceSupport" \
		"/Users/runner/Library/Android" \
		"/usr/local/lib/android" \
		"/opt/homebrew/share/dotnet" \
		"/usr/local/share/dotnet" \
		|| true

	df -h
}

fg_PrepareMacOSDependencies()
{
	fg_FreeMacOSDiskSpace

	for Formula in cmake coreutils ninja lua pstree swig zstd; do
		if ! brew list "$Formula" >/dev/null 2>&1; then
			brew install "$Formula" --quiet
		fi
	done
}

fg_DisableMacOSSpotlight()
{
	if ! command -v mdutil >/dev/null 2>&1; then
		return 0
	fi

	echo "::group::Spotlight status before disable"
	mdutil -as || true
	echo "::endgroup::"

	sudo mdutil -a -i off || true
	sudo mdutil -a -d || true

	echo "::group::Spotlight status after disable"
	mdutil -as || true
	echo "::endgroup::"
}

fg_MarkMacOSBuildRootNoIndex()
{
	if [[ "$PLATFORM" != "macOS" ]]; then
		return 0
	fi

	touch "$MALTERLIB_LLVM_BUILD_ROOT/.metadata_never_index" || true

	if command -v mdutil >/dev/null 2>&1; then
		sudo mdutil -i off "$MALTERLIB_LLVM_BUILD_ROOT" || true
		sudo mdutil -d "$MALTERLIB_LLVM_BUILD_ROOT" || true
	fi
}

fg_EnsureWindowsCommand()
{
	local Command="$1"
	local Package="$2"
	shift 2

	if ! command -v "$Command" >/dev/null 2>&1; then
		choco install "$Package" --no-progress --yes "$@"
	fi
}

fg_PrepareWindowsDependencies()
{
	fg_EnsureWindowsCommand cmake cmake
	fg_EnsureWindowsCommand ninja ninja
	fg_EnsureWindowsCommand perl strawberryperl
	fg_EnsureWindowsCommand zstd zstandard --version 1.5.7.20250308

	local ZstdDir
	ZstdDir="$(
		powershell -NoProfile -NonInteractive -Command '
			$Command = Get-Command zstd -ErrorAction SilentlyContinue
			if ($Command) {
				Split-Path -Parent $Command.Source
			}
		' | tr -d '\r' | tail -1
	)"
	if [[ -n "$ZstdDir" ]]; then
		echo "$ZstdDir" >> "$GITHUB_PATH"
		export PATH="$ZstdDir:$PATH"
	fi
}

fg_NormalizeRepositoryTimestamps()
{
	if [[ "$PLATFORM" == "Windows" ]]; then
		return
	fi

	bash ./.github/workflows/Normalize_Repository_Timestamps.sh "$PWD"
}

fg_PrepareRepositories()
{
	local RestoreNounset=false
	if [[ "$-" == *u* ]]; then
		set +u
		RestoreNounset=true
	fi

	source ./.github/workflows/Prepare_Repositories.sh

	if [[ "$RestoreNounset" == "true" ]]; then
		set -u
	fi

	./mib generate
	fg_NormalizeRepositoryTimestamps
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

	if [[ -z "$AvailableMount" ]]; then
		echo "/"
	else
		echo "$AvailableMount"
	fi
}

fg_SelectScratch()
{
	local BestBuildMount

	if [[ "$MALTERLIB_RUNNING_IN_CONTAINER" == "true" ]]; then
		MALTERLIB_LLVM_BUILD_ROOT="${MALTERLIB_LLVM_BUILD_ROOT:-/llvm-build/Build}"
		MALTERLIB_LLVM_ARTIFACT_ROOT="${MALTERLIB_LLVM_ARTIFACT_ROOT:-$MALTERLIB_LLVM_BUILD_ROOT}"
	elif [[ "$PLATFORM" == "Windows" ]]; then
		MALTERLIB_LLVM_BUILD_ROOT="/c/CompiledFiles/llvm-$ARCH"
		MALTERLIB_LLVM_ARTIFACT_ROOT="$MALTERLIB_LLVM_BUILD_ROOT"
	elif [[ "$PLATFORM" == "Linux" ]]; then
		BestBuildMount="$(fg_GetBestLinuxBuildMount)"
		if [[ -z "$BestBuildMount" || "$BestBuildMount" == "/" ]]; then
			MALTERLIB_LLVM_BUILD_ROOT="${RUNNER_TEMP%/}/MalterlibLLVM-$PLATFORM-$ARCH"
		else
			MALTERLIB_LLVM_BUILD_ROOT="${BestBuildMount%/}/MalterlibLLVM-$PLATFORM-$ARCH"
		fi
		if [[ "$BUILD_IN_CONTAINER" == "true" ]]; then
			MALTERLIB_LLVM_ARTIFACT_ROOT="$MALTERLIB_LLVM_BUILD_ROOT/Build"
		else
			MALTERLIB_LLVM_ARTIFACT_ROOT="$MALTERLIB_LLVM_BUILD_ROOT"
		fi
	else
		MALTERLIB_LLVM_BUILD_ROOT="${RUNNER_TEMP%/}/MalterlibLLVM-$PLATFORM-$ARCH.noindex"
		if [[ "$BUILD_IN_CONTAINER" == "true" ]]; then
			MALTERLIB_LLVM_ARTIFACT_ROOT="$MALTERLIB_LLVM_BUILD_ROOT/Build"
		else
			MALTERLIB_LLVM_ARTIFACT_ROOT="$MALTERLIB_LLVM_BUILD_ROOT"
		fi
	fi

	if [[ "$PLATFORM" == "Linux" && "$MALTERLIB_RUNNING_IN_CONTAINER" != "true" ]]; then
		sudo rm -rf "$MALTERLIB_LLVM_BUILD_ROOT"
		sudo mkdir -p "$MALTERLIB_LLVM_ARTIFACT_ROOT"
		sudo chown -R "$(id -u):$(id -g)" "$MALTERLIB_LLVM_BUILD_ROOT"
	else
		rm -rf "$MALTERLIB_LLVM_BUILD_ROOT"
		mkdir -p "$MALTERLIB_LLVM_ARTIFACT_ROOT"
	fi

	export MALTERLIB_LLVM_BUILD_ROOT
	export MALTERLIB_LLVM_ARTIFACT_ROOT
	echo "Selected LLVM build root: $MALTERLIB_LLVM_BUILD_ROOT"
	echo "Selected LLVM artifact root: $MALTERLIB_LLVM_ARTIFACT_ROOT"
	df -h "$MALTERLIB_LLVM_BUILD_ROOT" || true
}

fg_RestoreBuildState()
{
	local Archive
	Archive="$(find BuildState -name '*.tar.zst' -print -quit)"
	if [[ -z "$Archive" ]]; then
		echo "Downloaded build state artifact did not contain a .tar.zst file"
		exit 1
	fi

	mkdir -p "$MALTERLIB_LLVM_ARTIFACT_ROOT"
	local BsdTar
	BsdTar="$(fg_GetBundledBsdTar)"
	"$BsdTar" -xf "$Archive" -C "$MALTERLIB_LLVM_ARTIFACT_ROOT"
}

fg_GetBundledBsdTar()
{
	local TarArch="$ARCH"

	local BsdTar="Binaries/Malterlib/$PLATFORM/$TarArch/bsdtar"
	if [[ ! -f "$BsdTar" && -f "$BsdTar.exe" ]]; then
		BsdTar="$BsdTar.exe"
	fi
	if [[ ! -f "$BsdTar" ]]; then
		echo "Unable to find bundled bsdtar at Binaries/Malterlib/$PLATFORM/$TarArch" >&2
		exit 1
	fi

	echo "$BsdTar"
}

fg_CreateTarZstdArchive()
{
	local Archive="$1"
	shift

	local BsdTar
	BsdTar="$(fg_GetBundledBsdTar)"
	"$BsdTar" -caf "$Archive" "$@"
}

fg_RunUnixStage()
{
	export MalterlibLLVMPlatform="$PLATFORM"
	export MalterlibLLVMArch="$ARCH"
	export MalterlibLLVMBuildRoot="$MALTERLIB_LLVM_BUILD_ROOT"
	export LLVMBuildStage="$LLVM_STAGE"

	if [[ "$PLATFORM" == "Linux" ]]; then
		export InstallDependencies=true
	fi

	./Malterlib/Tool/Scripts/BuildLLVMDistribution.sh
}

fg_RunUnixContainerStage()
{
	: "${CONTAINER_IMAGE:?}"
	: "${CONTAINER_PLATFORM:?}"

	echo "::group::Host environment before container"
	fg_PrintSafeEnv
	echo "::endgroup::"

	local WorkspaceParent
	local WorkspaceName
	local ContainerWorkspace
	WorkspaceParent="$(cd .. && pwd)"
	WorkspaceName="$(basename "$PWD")"
	ContainerWorkspace="/opt/Source/$WorkspaceName"

	local DockerResult=0
	docker run --rm \
		--platform "$CONTAINER_PLATFORM" \
		-e PLATFORM="$PLATFORM" \
		-e ARCH="$ARCH" \
		-e BUILD_IN_CONTAINER=true \
		-e MALTERLIB_RUNNING_IN_CONTAINER=true \
		-e BuildPlatform="$PLATFORM" \
		-e BuildArchitecture="$ARCH" \
		-e BuildConfiguration=Debug \
		-e BuildSanitizer=None \
		-e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
		-e MalterlibBuildShowProgress="${MalterlibBuildShowProgress:-false}" \
		-e Malterlib_UseCachedEnvironment="${Malterlib_UseCachedEnvironment:-false}" \
		-e Malterlib_UseUserSettings="${Malterlib_UseUserSettings:-false}" \
		-e MalterlibImportUpdateCache="${MalterlibImportUpdateCache:-false}" \
		-e MalterlibRepositoryHardReset="${MalterlibRepositoryHardReset:-true}" \
		-e MalterlibSyncBinaryLLVMRepositories="${MalterlibSyncBinaryLLVMRepositories:-false}" \
		-e HasLLVMRepository="${HasLLVMRepository:-true}" \
		-e RunningCI="${RunningCI:-true}" \
		-e MalterlibLLVMPlatform="$PLATFORM" \
		-e MalterlibLLVMArch="$ARCH" \
		-e MalterlibBuildScratchRoot="/llvm-build/Prepare" \
		-e MalterlibLLVMBuildRoot="/llvm-build/Build" \
		-e MALTERLIB_LLVM_BUILD_ROOT="/llvm-build/Build" \
		-e MALTERLIB_LLVM_ARTIFACT_ROOT="/llvm-build/Build" \
		-e LLVM_STAGE="$LLVM_STAGE" \
		-e LLVMBuildStage="$LLVM_STAGE" \
		-e LLVMNinjaTimeoutDeadlineSeconds="${LLVMNinjaTimeoutDeadlineSeconds:-}" \
		-e LLVMNinjaTimeoutSeconds="${LLVMNinjaTimeoutSeconds:-}" \
		-e LLVM_PARALLEL_LINK_JOBS="${LLVM_PARALLEL_LINK_JOBS:-}" \
		-e RESTORE_BUILD_STATE="$RESTORE_BUILD_STATE" \
		-e ARCHIVE_BUILD_STATE="$ARCHIVE_BUILD_STATE" \
		-e CREATE_DISTRIBUTION_ARCHIVE="$CREATE_DISTRIBUTION_ARCHIVE" \
		-e InstallDependencies=true \
		-e MALTERLIB_CONTAINER_WORKSPACE="$ContainerWorkspace" \
		-e DEBIAN_FRONTEND=noninteractive \
		-e HOME=/tmp \
		-v "$WorkspaceParent:/opt/Source" \
		-v "$MALTERLIB_LLVM_BUILD_ROOT:/llvm-build" \
		-w "$ContainerWorkspace" \
		"$CONTAINER_IMAGE" \
		bash -leo pipefail ./.github/workflows/Build_LLVM_Container_Stage.sh || DockerResult=$?

	sudo chown -R "$(id -u):$(id -g)" "$PWD" "$MALTERLIB_LLVM_BUILD_ROOT" || true

	local StageStatus=""
	if [[ -f "$(fg_StageStatusFile)" ]]; then
		StageStatus="$(cat "$(fg_StageStatusFile)")"
	fi

	if [[ "$DockerResult" -eq 0 && "$CREATE_DISTRIBUTION_ARCHIVE" == "true" && "$StageStatus" != "running" ]]; then
		fg_CopyContainerDistributionArchiveToWorkspace
	fi

	fg_EmitStageStatusFromFile

	return "$DockerResult"
}

fg_CopyContainerDistributionArchiveToWorkspace()
{
	local ArchiveName="MalterlibLLVM-$PLATFORM-$ARCH.tar.zst"
	local WorkspaceArchive="$PWD/Artifacts/$ArchiveName"
	local ArtifactRootArchive="$MALTERLIB_LLVM_ARTIFACT_ROOT/Artifacts/$ArchiveName"
	local WorkspaceArtifacts="$PWD/Artifacts"

	if [[ -L "$WorkspaceArtifacts" && ! -e "$WorkspaceArtifacts" ]]; then
		rm -f "$WorkspaceArtifacts"
	fi

	if [[ ! -f "$WorkspaceArchive" && -f "$ArtifactRootArchive" ]]; then
		mkdir -p "$WorkspaceArtifacts"
		cp -f "$ArtifactRootArchive" "$WorkspaceArchive"
	fi

	if [[ ! -f "$WorkspaceArchive" ]]; then
		echo "Missing container distribution archive in workspace: $WorkspaceArchive" >&2
		echo "Checked artifact root archive: $ArtifactRootArchive" >&2
		exit 1
	fi

	if [[ -f "$ArtifactRootArchive" && "$ArtifactRootArchive" != "$WorkspaceArchive" ]]; then
		rm -f "$ArtifactRootArchive"
	fi

	ls -lh "$WorkspaceArchive"
}

fg_RunWindowsStage()
{
	export MalterlibLLVMPlatform="$PLATFORM"
	export MalterlibLLVMArch="$ARCH"
	export MalterlibLLVMBuildRoot="$MALTERLIB_LLVM_BUILD_ROOT"
	export LLVMBuildStage="$LLVM_STAGE"

	./Malterlib/Tool/Scripts/BuildLLVMDistributionWindows.sh
}

fg_ArchiveBuildState()
{
	if [[ ! -d "$MALTERLIB_LLVM_ARTIFACT_ROOT/build" ]]; then
		echo "Missing build directory: $MALTERLIB_LLVM_ARTIFACT_ROOT/build"
		exit 1
	fi

	mkdir -p BuildStates
	local Archive="$PWD/BuildStates/MalterlibLLVMBuild-$PLATFORM-$ARCH-$LLVM_STAGE.tar.zst"
	rm -f "$Archive"
	fg_CreateTarZstdArchive "$Archive" -C "$MALTERLIB_LLVM_ARTIFACT_ROOT" build
	ls -lh "$Archive"
}

fg_CreateDistributionArchive()
{
	local DistributionDir="Binaries/MalterlibLLVM/$PLATFORM/$ARCH"
	if [[ ! -d "$DistributionDir/bin" ]]; then
		echo "Missing LLVM distribution bin directory: $DistributionDir/bin"
		exit 1
	fi

	mkdir -p Artifacts
	local Archive="$PWD/Artifacts/MalterlibLLVM-$PLATFORM-$ARCH.tar.zst"
	rm -f "$Archive"
	fg_CreateTarZstdArchive "$Archive" -C "$DistributionDir" .
	ls -lh "$Archive"

	if [[ "$MALTERLIB_RUNNING_IN_CONTAINER" == "true" ]]; then
		mkdir -p "$MALTERLIB_LLVM_ARTIFACT_ROOT/Artifacts"
		cp -f "$Archive" "$MALTERLIB_LLVM_ARTIFACT_ROOT/Artifacts/"
		ls -lh "$MALTERLIB_LLVM_ARTIFACT_ROOT/Artifacts/$(basename "$Archive")"
	fi
}

case "$PLATFORM" in
	Linux)
		if [[ "$MALTERLIB_RUNNING_IN_CONTAINER" != "true" ]]; then
			fg_FreeLinuxDiskSpace
			fg_SetLinuxSwap
		fi
		;;
	macOS)
		fg_DisableMacOSSpotlight
		fg_PrepareMacOSDependencies
		;;
	Windows)
		fg_PrepareWindowsDependencies
		;;
	*)
		echo "Unsupported platform: $PLATFORM"
		exit 1
		;;
esac

fg_SelectScratch
fg_MarkMacOSBuildRootNoIndex

if [[ "$BUILD_IN_CONTAINER" == "true" && "$MALTERLIB_RUNNING_IN_CONTAINER" != "true" ]]; then
	fg_RunUnixContainerStage
else
	if [[ "$MALTERLIB_RUNNING_IN_CONTAINER" == "true" ]]; then
		echo "::group::Container builder environment"
		fg_PrintSafeEnv
		echo "::endgroup::"
	fi

	fg_PrepareRepositories
	if [[ "$RESTORE_BUILD_STATE" == "true" ]]; then
		fg_RestoreBuildState
	fi

	StageResult=0
	if [[ "$PLATFORM" == "Windows" ]]; then
		fg_RunWindowsStage || StageResult="$?"
	else
		fg_RunUnixStage || StageResult="$?"
	fi

	if [[ "$StageResult" -eq 124 ]]; then
		fg_ArchiveBuildState
		fg_SetStageStatus running
		exit 0
	elif [[ "$StageResult" -ne 0 ]]; then
		exit "$StageResult"
	fi

	if [[ "$ARCHIVE_BUILD_STATE" == "true" ]]; then
		fg_ArchiveBuildState
	fi

	if [[ "$CREATE_DISTRIBUTION_ARCHIVE" == "true" ]]; then
		fg_CreateDistributionArchive
	fi

	fg_SetStageStatus success
fi
