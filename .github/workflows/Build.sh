set -ex
echo ${SECONDS}s

echo Num CPU threads: `getconf _NPROCESSORS_ONLN`

cd `dirname ${BASH_SOURCE[0]}`
cd ../..
RootDir="$PWD"

rm -rf "$RootDir/Artifacts"
mkdir -p "$RootDir/Artifacts"

source ./.github/workflows/GitSetup.sh

FolderCompiledFiles=/c/BuildSystem/CompiledFiles

df -h

CompiledFiles=/opt/CompiledFiles
Deploy=/opt/Deploy

if [[ "$BuildPlatform" == "Windows" ]]; then
	CompiledFiles="/c/BuildSystem/CompiledFiles"
	Deploy="/c/BuildSystem/Deploy"
	export EnablePlatform_Windows="true"
	export EnableArchitecture_x86="false"
	export EnableArchitecture_x64="false"
	export EnableArchitecture_${BuildArchitecture}="true"

	export EnableDebugConfig="false"
	export EnableDebugInlinedConfig="false"
	export EnableReleaseConfig="false"
	export EnableReleaseTestingConfig="false"

	if [[ "$BuildConfiguration" == "Debug" ]]; then
		export EnableDebugConfig="true"
	elif [[ "$BuildConfiguration" == "Release Testing (Tests)" ]]; then
		export EnableReleaseTestingConfig="true"
	elif [[ "$BuildConfiguration" == "Release (Tests)" ]]; then
		export EnableReleaseConfig="true"
	fi
else
	export EnablePlatform_Linux="true"
	export EnablePlatform_macOS="true"
	export EnableArchitecture_x64="true"
	export EnableArchitecture_x86="false"
	export EnableArchitecture_arm64="false"
fi

mkdir -p "$CompiledFiles"
mkdir -p BuildSystem/Default
rm -rf "$Deploy/"* || true
mkdir -p "$Deploy"

echo ${SECONDS}s
if [ -d Malterlib/Core ]; then
	git -C Malterlib/Core reset --hard
fi

./mib setup_only

source Malterlib/Core/Scripts/Detect.sh
if [[ "$BuildPlatform" == "Windows" ]] && [[ "$MalterlibDeploySymbols" == "true" ]]; then
	rm -rf "$RootDir/Symbols"
	mkdir -p "$RootDir/Symbols"
	export MalterlibDeploySymbolsPath="`MalterlibConvertPath \"$RootDir/Symbols\"`"
fi

export MalterlibDependenciesDirectory="`MalterlibConvertPath \"$CompiledFiles/Dependencies\"`"
export MalterlibCompiledFiles="`MalterlibConvertPath \"$CompiledFiles/\"`"

echo ${SECONDS}s
./mib update_repos

df -h

MalterlibDeployRoot="`MalterlibConvertPath \"$Deploy\"`"
echo MalterlibDeployRoot: $MalterlibDeployRoot
echo "DefaultRoot \"${MalterlibDeployRoot}\"" > BuildSystem/Default/PostCopy.MConfig
echo ${SECONDS}s
./mib prebuild Malterlib Tests

df -h

echo ${SECONDS}s
if ! ./mib build Tests "$BuildPlatform" $BuildArchitecture "$BuildConfiguration" ; then
  echo Build failed
  df -h
  exit 1
fi
echo ${SECONDS}s

df -h

pwd

pushd "$Deploy"
DeployDirectory=`ls .`
echo DeployDirectory: $DeployDirectory

echo tar -caf "$RootDir/Artifacts/Deploy.tar.zst" "$DeployDirectory"
tar -caf "$RootDir/Artifacts/Deploy.tar.zst" "$DeployDirectory"

df -h
