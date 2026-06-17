#!/usr/bin/env bash
set -euo pipefail

Rows=(
	"INPUT_LINUX_X64|Linux x64|Linux|x64|ubuntu-22.04|false|||stage1|instrumented|training|training"
	"INPUT_LINUX_ARM64|Linux arm64|Linux|arm64|ubuntu-22.04-arm|false|||stage1|instrumented|training|training"
	"INPUT_LINUX_X86|Linux x86|Linux|x86|ubuntu-22.04|true|debian:12@sha256:8a8cd02c5912770b4980228a54d4aff9e4f986f1eb2525d2d371dec5232cefcc|linux/386|stage1|||stage1"
	"INPUT_MACOS_ARM64|macOS arm64|macOS|arm64|macos-26|false|||stage1|instrumented|training|training"
	"INPUT_MACOS_X64|macOS x64|macOS|x64|macos-26-intel|false|||stage1|instrumented|training|training"
	"INPUT_WINDOWS_X64|Windows x64|Windows|x64|windows-2022|false|||stage0|pgo||pgo"
	"INPUT_WINDOWS_ARM64|Windows arm64|Windows|arm64|windows-11-arm|false|||stage0|pgo||pgo"
)

Matrix='{"include":['
Separator=""

for Row in "${Rows[@]}"; do
	IFS='|' read -r InputName Display Platform Arch Runner BuildInContainer ContainerImage ContainerPlatform Stage1 Stage2 Stage3 FinalRestoreStage <<< "$Row"
	if [[ "${!InputName}" != "true" ]]; then
		continue
	fi

	Matrix+="$Separator"
	Matrix+="{\"display\":\"$Display\",\"platform\":\"$Platform\",\"arch\":\"$Arch\",\"runner\":\"$Runner\",\"build_in_container\":$BuildInContainer,\"container_image\":\"$ContainerImage\",\"container_platform\":\"$ContainerPlatform\",\"stage_1\":\"$Stage1\",\"stage_2\":\"$Stage2\",\"stage_3\":\"$Stage3\",\"final_restore_stage\":\"$FinalRestoreStage\"}"
	Separator=","
done

Matrix+=']}'

if [[ "$Matrix" == '{"include":[]}' ]]; then
	echo "At least one platform/architecture checkbox must be enabled." >&2
	exit 1
fi

echo "matrix=$Matrix" >> "$GITHUB_OUTPUT"
