# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set -ex

source "$(dirname "${BASH_SOURCE[0]}")/Prepare_Repositories.sh"

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
