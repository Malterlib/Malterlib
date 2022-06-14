set -ex

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

env

#df -h

#MSYS_NO_PATHCONV=1 compact /C /S /I /Q /EXE || true
#MSYS_NO_PATHCONV=1 compact /C /S /I /Q || true

#df -h

#pushd /c/BuildSystem

#MSYS_NO_PATHCONV=1 compact /C /S /I /Q /EXE || true
#MSYS_NO_PATHCONV=1 compact /C /S /I /Q || true
#popd

#df -h

./mib setup_only

source Malterlib/Core/Scripts/Detect.sh
export MalterlibDependenciesDirectory="`MalterlibConvertPath \"$CompiledFiles/Dependencies\"`"
export MalterlibCompiledFiles="`MalterlibConvertPath \"$CompiledFiles/\"`"

./mib update_repos

df -h

MalterlibDeployRoot="`MalterlibConvertPath \"$Deploy\"`"
echo MalterlibDeployRoot: $MalterlibDeployRoot
echo "DefaultRoot \"${MalterlibDeployRoot}\"" > BuildSystem/Default/PostCopy.MConfig
./mib prebuild Malterlib Tests

df -h

if ! ./mib build Tests "$BuildPlatform" $BuildArchitecture "$BuildConfiguration" ; then
  echo Build failed
  df -h
  exit 1
fi

df -h

pwd

pushd "$Deploy"
DeployDirectory=`ls .`
echo DeployDirectory: $DeployDirectory

echo tar -caf "$RootDir/Artifacts/Deploy.tar.zst" "$DeployDirectory"
tar -caf "$RootDir/Artifacts/Deploy.tar.zst" "$DeployDirectory"

df -h
