# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set -ex
echo ${SECONDS}s

echo Num CPU threads: `getconf _NPROCESSORS_ONLN`

cd `dirname ${BASH_SOURCE[0]}`
cd ../..
RootDir="$PWD"

fg_GetAvailableSpaceKb()
{
	local Path="$1"
	local Filesystem
	local Blocks
	local Used
	local Available
	local Capacity
	local Mount

	while read -r Filesystem Blocks Used Available Capacity Mount; do
		if [[ "$Filesystem" == "Filesystem" ]]; then
			continue
		fi

		if [[ "$Available" =~ ^[0-9]+$ ]]; then
			echo "$Available"
			return 0
		fi
	done < <(df -Pk "$Path" 2>/dev/null)

	return 1
}

fg_PrepareWritableDirectory()
{
	local Path="$1"
	local TestDir
	local UserName

	if ! mkdir -p "$Path" 2>/dev/null; then
		if ! command -v sudo >/dev/null 2>&1; then
			return 1
		fi

		sudo mkdir -p "$Path" || return 1
	fi

	if ! TestDir="$(mktemp -d "$Path/malterlib-writable.XXXXXX" 2>/dev/null)"; then
		if ! command -v sudo >/dev/null 2>&1; then
			return 1
		fi

		UserName="${USER:-$(id -un)}"
		sudo chown "$UserName" "$Path" || return 1
		TestDir="$(mktemp -d "$Path/malterlib-writable.XXXXXX" 2>/dev/null)" || return 1
	fi

	rmdir "$TestDir"
}

fg_SelectLargestWritablePath()
{
	local BestPath=""
	local BestAvailable=-1
	local Candidate
	local Available

	for Candidate in "$@"; do
		if [[ -z "$Candidate" ]]; then
			continue
		fi

		Candidate="${Candidate%/}"
		if ! fg_PrepareWritableDirectory "$Candidate"; then
			continue
		fi

		Available="$(fg_GetAvailableSpaceKb "$Candidate")" || continue
		if (( Available > BestAvailable )); then
			BestPath="$Candidate"
			BestAvailable="$Available"
		fi
	done

	if [[ -z "$BestPath" ]]; then
		return 1
	fi

	echo "$BestPath"
}

df -h

CompiledFiles=/opt/CompiledFiles
Deploy=/opt/Deploy

if [[ -n "${RUNNER_TEMP:-}" ]]; then
	CompiledFiles="${RUNNER_TEMP%/}/CompiledFiles"
	Deploy="${RUNNER_TEMP%/}/Deploy"
fi

SingleConfiguration="$BuildConfiguration"
SingleConfiguration="${SingleConfiguration%% (*}"

export SinglePlatform="$BuildPlatform"
export SingleArchitecture="$BuildArchitecture"
export SingleConfiguration

export MalterlibEnableSanitizerReleaseConfigs="false"
export MalterlibSupportSanitizerEnable_Thread="false"
export MalterlibSupportSanitizerEnable_Address="false"
export MalterlibSupportSanitizerEnable_UndefinedBehavior="false"
export MalterlibSupportSanitizerEnable_NoRecover="false"

case "$BuildPlatform" in
	Windows)
		BuildScratchRoot="/c/BuildSystem"
		CompiledFiles="$BuildScratchRoot/CompiledFiles"
		Deploy="$BuildScratchRoot/Deploy"
		;;
	Linux)
		if [[ -n "${MalterlibBuildScratchRoot:-}" ]]; then
			BuildScratchRoot="${MalterlibBuildScratchRoot%/}"
			fg_PrepareWritableDirectory "$BuildScratchRoot" ||
			{
				echo "Unable to create writable build scratch directory: $BuildScratchRoot"
				exit 1
			}
		else
			BuildScratchCandidates=(
				"${RUNNER_TEMP:+${RUNNER_TEMP%/}/MalterlibBuild}"
				"/mnt/MalterlibBuild"
				"/opt/MalterlibBuild"
				"/tmp/MalterlibBuild"
				"$RootDir/../MalterlibBuild"
			)

			while read -r Filesystem Blocks Used Available Capacity Mount; do
				if [[ "$Filesystem" == "Filesystem" ]]; then
					continue
				fi

				case "$Mount" in
					/dev|/dev/*|/proc|/proc/*|/run|/run/*|/sys|/sys/*)
						continue
						;;
				esac

				BuildScratchCandidates+=("${Mount%/}/MalterlibBuild")
			done < <(df -Pk)

			BuildScratchRoot="$(fg_SelectLargestWritablePath "${BuildScratchCandidates[@]}")" ||
			{
				echo "Unable to find a writable build scratch directory"
				exit 1
			}
		fi

		CompiledFiles="$BuildScratchRoot/CompiledFiles"
		Deploy="$BuildScratchRoot/Deploy"
		;;
	macOS)
		;;
	*)
		echo "Unsupported BuildPlatform: $BuildPlatform"
		exit 1
		;;
esac

if [[ -n "${BuildScratchRoot:-}" ]]; then
	mkdir -p "$BuildScratchRoot"
	echo "BuildScratchRoot: $BuildScratchRoot"
	df -h "$BuildScratchRoot"
fi

Artifacts="$RootDir/Artifacts"
rm -rf "$Artifacts"

if [[ "$BuildPlatform" == "Linux" ]]; then
	ArtifactsScratch="$BuildScratchRoot/Artifacts"
	rm -rf "$ArtifactsScratch"
	mkdir -p "$ArtifactsScratch"
	ln -s "$ArtifactsScratch" "$Artifacts"
else
	mkdir -p "$Artifacts"
fi

case "$BuildArchitecture" in
	x86)
		;;
	x64)
		;;
	arm64)
		;;
	*)
		echo "Unsupported BuildArchitecture: $BuildArchitecture"
		exit 1
		;;
esac

case "${BuildSanitizer:-None}" in
	""|None)
		;;
	Thread)
		export MalterlibSupportSanitizerEnable_Thread="true"
		export MalterlibSupportSanitizerEnable_NoRecover="true"
		;;
	Address)
		export MalterlibSupportSanitizerEnable_Address="true"
		export MalterlibSupportSanitizerEnable_NoRecover="true"
		;;
	UndefinedBehavior)
		export MalterlibSupportSanitizerEnable_UndefinedBehavior="true"
		export MalterlibSupportSanitizerEnable_NoRecover="true"
		;;
	*)
		echo "Unsupported BuildSanitizer: $BuildSanitizer"
		exit 1
		;;
esac

mkdir -p "$CompiledFiles"
mkdir -p BuildSystem/Default
rm -rf "$Deploy/"* || true
mkdir -p "$Deploy"

if [[ "$BuildPlatform" == "Linux" ]]; then
	BuildTemp="$BuildScratchRoot/Tmp"
	mkdir -p "$BuildTemp"
	export TMPDIR="$BuildTemp"
	export TMP="$BuildTemp"
	export TEMP="$BuildTemp"
fi

if [[ "$BuildPlatform" == "Linux" ]]; then
	MalterlibGitLfsStorage="${MalterlibGitLfsStorage:-$BuildScratchRoot/MalterlibGitLfsStorage}"
else
	MalterlibGitLfsStorage="${MalterlibGitLfsStorage:-$RootDir/../MalterlibGitLfsStorage}"
fi
mkdir -p "$MalterlibGitLfsStorage"
git config --global lfs.storage "$MalterlibGitLfsStorage"

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
	if [[ "$BuildPlatform" == "Linux" ]]; then
		GitAskPass="$BuildScratchRoot/malterlib-git-askpass.sh"
	else
		GitAskPass="${RUNNER_TEMP:-$Artifacts}/malterlib-git-askpass.sh"
	fi
	mkdir -p "$(dirname "$GitAskPass")"
	cat > "$GitAskPass" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	*Username*) printf '%s\n' 'x-access-token' ;;
	*Password*) printf '%s\n' "$GITHUB_TOKEN" ;;
	*) printf '%s\n' "$GITHUB_TOKEN" ;;
esac
EOF
	chmod 700 "$GitAskPass"
	export GIT_ASKPASS="$GitAskPass"
	export SSH_ASKPASS="$GitAskPass"
	export GIT_TERMINAL_PROMPT=0
fi

echo ${SECONDS}s
if [ -d Malterlib/Core ]; then
	git -C Malterlib/Core reset --hard
fi

./mib setup_only

source Malterlib/Core/Scripts/Detect.sh

export MalterlibCompiledFiles="`MalterlibConvertPath \"$CompiledFiles/\"`"

./mib setup

if [[ "$BuildPlatform" == "Windows" ]] && [[ "$MalterlibDeploySymbols" == "true" ]]; then
	rm -rf "$RootDir/Symbols"
	mkdir -p "$RootDir/Symbols"
	export MalterlibDeploySymbolsPath="`MalterlibConvertPath \"$RootDir/Symbols\"`"
fi

echo ${SECONDS}s
./mib update-repos

if [[ "${MalterlibCacheRepositoriesOnly:-false}" == "true" ]]; then
	exit 0
fi

# Fail build is licensing is wrong
./mib check-license --terminal-width=200

df -h

MalterlibDeployRoot="`MalterlibConvertPath \"$Deploy\"`"
echo MalterlibDeployRoot: $MalterlibDeployRoot
echo "DefaultRoot \"${MalterlibDeployRoot}\"" > BuildSystem/Default/PostCopy.MConfig
echo ${SECONDS}s
./mib prebuild Malterlib Tests

df -h

BuildAttempt=1
while true; do
	echo ${SECONDS}s
	if ! ./mib build Tests "$BuildPlatform" "$BuildArchitecture" "$BuildConfiguration" ; then
		echo Build failed
		df -h
		exit 1
	fi
	echo ${SECONDS}s

	df -h

	pwd

	pushd "$Deploy"
	shopt -s nullglob
	DeployDirectories=(*)
	shopt -u nullglob

	if [[ ${#DeployDirectories[@]} -ne 0 ]]; then
		break
	fi

	echo "No files were deployed to $Deploy after the build succeeded"
	ls -la
	popd

	if [[ "$BuildPlatform" == "Windows" ]] && [[ "$BuildAttempt" -eq 1 ]]; then
		echo "Retrying Windows build once after empty deploy output"
		BuildAttempt=2
		continue
	fi

	exit 1
done

if [[ ${#DeployDirectories[@]} -ne 1 ]]; then
	echo "Expected exactly one deploy directory in $Deploy, found ${#DeployDirectories[@]} entries"
	ls -la
	exit 1
fi

DeployDirectory="${DeployDirectories[0]}"
if [[ ! -d "$DeployDirectory" ]]; then
	echo "Expected deploy entry in $Deploy to be a directory: $DeployDirectory"
	ls -la
	exit 1
fi

echo "DeployDirectory: $DeployDirectory"

BsdTar="$MToolDirectory/bsdtar"
if [[ ! -f "$BsdTar" && -f "$BsdTar.exe" ]]; then
	BsdTar="$BsdTar.exe"
fi
if [[ ! -f "$BsdTar" ]]; then
	echo "Unable to find bundled bsdtar at $MToolDirectory"
	exit 1
fi

echo "$BsdTar" -caf "$Artifacts/Deploy.tar.zst" "$DeployDirectory"
"$BsdTar" -caf "$Artifacts/Deploy.tar.zst" "$DeployDirectory"

if [[ "$BuildPlatform" == "Windows" ]]; then
	cp "$BsdTar" "$Artifacts/bsdtar.exe"
fi

df -h
