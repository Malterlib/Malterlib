#!/usr/bin/env bash
set -eo pipefail

fg_PrintSafeEnv()
{
	env | sort | sed -E 's/^([^=]*(TOKEN|PASSWORD|SECRET|KEY|CREDENTIAL|AUTH)[^=]*=).*/\1<masked>/I'
}

echo "::group::Container root environment"
fg_PrintSafeEnv
echo "::endgroup::"

apt-get update
apt-get install -y ca-certificates curl git git-lfs m4 sudo zstd
git lfs install --system --skip-repo

WorkspacePath="${MALTERLIB_CONTAINER_WORKSPACE:-$PWD}"
BuildUid="$(stat -c "%u" "$WorkspacePath")"
BuildGid="$(stat -c "%g" "$WorkspacePath")"
BuildUser=builder

if ! getent group "$BuildGid" >/dev/null; then
	groupadd -g "$BuildGid" "$BuildUser"
fi
if ! getent passwd "$BuildUid" >/dev/null; then
	useradd -m -u "$BuildUid" -g "$BuildGid" -s /bin/bash "$BuildUser"
else
	BuildUser="$(getent passwd "$BuildUid" | cut -d: -f1)"
fi

echo "$BuildUser ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$BuildUser"
chmod 0440 "/etc/sudoers.d/$BuildUser"

BuildHome="$(getent passwd "$BuildUid" | cut -d: -f6)"
BuildTemp="/llvm-build/Prepare/Tmp"
mkdir -p "$BuildTemp/.MTool" "$BuildTemp/.mib"
chown -R "$BuildUid:$BuildGid" /llvm-build "$BuildHome"

sudo -E -u "$BuildUser" env \
	BUILD_IN_CONTAINER=true \
	MALTERLIB_RUNNING_IN_CONTAINER=true \
	MALTERLIB_LLVM_BUILD_ROOT=/llvm-build/Build \
	MALTERLIB_LLVM_ARTIFACT_ROOT=/llvm-build/Build \
	PLATFORM="$PLATFORM" \
	ARCH="$ARCH" \
	LLVM_STAGE="$LLVM_STAGE" \
	LLVM_PARALLEL_LINK_JOBS="${LLVM_PARALLEL_LINK_JOBS:-}" \
	RESTORE_BUILD_STATE="${RESTORE_BUILD_STATE:-false}" \
	ARCHIVE_BUILD_STATE="${ARCHIVE_BUILD_STATE:-false}" \
	CREATE_DISTRIBUTION_ARCHIVE="${CREATE_DISTRIBUTION_ARCHIVE:-false}" \
	HOME="$BuildHome" \
	USER="$BuildUser" \
	LOGNAME="$BuildUser" \
	TMPDIR="$BuildTemp" \
	TMP="$BuildTemp" \
	TEMP="$BuildTemp" \
	bash -leo pipefail ./.github/workflows/Build_LLVM_Run_Target_Stage.sh
