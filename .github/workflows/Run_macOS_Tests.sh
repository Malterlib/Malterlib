# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set -e

if ! which gtar; then
  brew install gnu-tar --quiet
fi
if ! which zstd; then
  brew install zstd --quiet
fi
if ! which node; then
  brew install node --quiet
fi
if ! which npm; then
  brew install npm --quiet
fi

PostgresBin=""
for Formula in postgresql@18 postgresql@17 postgresql@16 postgresql@15 postgresql; do
  Candidate="$(brew --prefix "$Formula" 2>/dev/null || true)/bin"
  if [[ -x "$Candidate/initdb" && -x "$Candidate/pg_ctl" ]]; then
    PostgresBin="$Candidate"
    break
  fi
done
if [[ -z "$PostgresBin" ]]; then
  brew install postgresql@17 --quiet
  PostgresBin="$(brew --prefix postgresql@17)/bin"
fi
export PATH="$PostgresBin:$PATH"
initdb --version
pg_ctl --version

pwd
echo Num CPU threads: `getconf _NPROCESSORS_ONLN`
ArtifactsPath="$PWD/Artifacts/Deploy.tar.zst"
sudo rm -rf /opt/Deploy
sudo mkdir -p /opt/Deploy
sudo chown $USER /opt/Deploy
cd /opt/Deploy
export MalterlibCrashDumpDir="$PWD/CrashDumps"
gtar -xf "$ArtifactsPath"
TestsDirName=`find Tests* -maxdepth 0`
if [[ "$TestsDirName" != "Tests" ]]; then
  mv "$TestsDirName" Tests
fi
cd Tests
./RunAllTests --quiet --launch-per-suite --suite-order slow_first --timeout 3600 -- --logs
sudo -E ./RunAllTests -g SuperUser --quiet --launch-per-suite --suite-order slow_first --timeout 3600 --no-parallel -- --logs
