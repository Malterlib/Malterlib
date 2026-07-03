# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set -e

# Shared between the native runner path and the container path

ConfigurePostgresPath() {
  if command -v initdb >/dev/null 2>&1 && command -v pg_ctl >/dev/null 2>&1; then
    return 0
  fi

  while IFS= read -r PostgresBin; do
    if [[ -x "$PostgresBin/initdb" && -x "$PostgresBin/pg_ctl" ]]; then
      export PATH="$PostgresBin:$PATH"
      return 0
    fi
  done < <(printf '%s\n' /usr/lib/postgresql/*/bin /usr/lib/postgresql*/bin /usr/pgsql-*/bin | sort -Vru)

  return 1
}

# Uses ArtifactsPath, TestsOwner, UserRun and SuperUserRun set up by the caller
ExtractAndRunTests() {
  if ! ConfigurePostgresPath; then
    echo "PostgreSQL initdb and pg_ctl were not found" >&2
    exit 1
  fi
  initdb --version
  pg_ctl --version

  echo Num CPU threads: `getconf _NPROCESSORS_ONLN`
  cd /Deploy
  export MalterlibCrashDumpDir="$PWD/CrashDumps"
  tar -xf "$ArtifactsPath"
  TestsDirName=`find Tests* -maxdepth 0`
  if [[ "$TestsDirName" != "Tests" ]]; then
    mv "$TestsDirName" Tests
  fi
  if [[ -n "${TestsOwner:-}" ]]; then
    chown -R "$TestsOwner" /Deploy
  fi

  cd Tests
  "${UserRun[@]}" ./RunAllTests --quiet --launch-per-suite --suite-order slow_first --timeout 3600 -- --logs
  "${SuperUserRun[@]}" ./RunAllTests -g SuperUser --quiet --launch-per-suite --suite-order slow_first --timeout 3600 --no-parallel -- --logs
}

if [[ "${1:-}" == "--inside-container" ]]; then
  export LANG=C.UTF-8

  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install --yes --no-install-recommends ca-certificates zstd postgresql nodejs npm util-linux passwd
  elif command -v dnf >/dev/null 2>&1; then
    dnf install --assumeyes ca-certificates zstd tar postgresql-server nodejs npm util-linux shadow-utils
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Syu --noconfirm ca-certificates zstd postgresql nodejs npm util-linux shadow
  elif command -v zypper >/dev/null 2>&1; then
    zypper --non-interactive install ca-certificates zstd tar gzip findutils postgresql-server nodejs-default npm-default util-linux shadow
  else
    echo "No supported package manager found" >&2
    exit 1
  fi

  if ! grep -q '^::1' /etc/hosts; then
    echo '::1 localhost ip6-localhost ip6-loopback' >> /etc/hosts
  fi

  useradd -m tester
  export XDG_RUNTIME_DIR=/run/user/$(id -u tester)
  mkdir -p "$XDG_RUNTIME_DIR"
  chown tester "$XDG_RUNTIME_DIR"

  mkdir -p /Deploy
  ArtifactsPath=/Artifacts/Deploy.tar.zst
  TestsOwner=tester
  UserRun=(env HOME=/home/tester runuser -p -u tester --)
  SuperUserRun=()
  ExtractAndRunTests
  exit 0
fi

if [[ -n "${Image:-}" ]]; then
  # Run the tests inside a container, re-entering this script with
  # --inside-container
  ScriptPath="$(realpath "${BASH_SOURCE[0]}")"
  DockerArgs=()
  if [[ -n "${ImagePlatform:-}" ]]; then
    DockerArgs+=(--platform "$ImagePlatform")
  fi
  # The resolver uses AI_ADDRCONFIG, which requires a non-loopback IPv6 address on the host,
  # so the container needs an IPv6-enabled network rather than just an enabled loopback
  if ! docker network inspect malterlib-tests >/dev/null 2>&1; then
    docker network create --ipv6 --subnet fd0c:a17e:51b5::/64 malterlib-tests
  fi
  docker run --rm --init \
    --network malterlib-tests \
    --shm-size=1g \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    "${DockerArgs[@]}" \
    -v "$PWD/Artifacts:/Artifacts:ro" \
    -v "$ScriptPath:/Run_Linux_Tests.sh:ro" \
    -e MalterlibFlakySuites \
    -e MalterlibTerminalWidth \
    -e MalterlibLogCategoryWidth \
    -e MalterlibFileLineOnDebugBreak \
    -e MalterlibConcurrency_DebugSubscriptions \
    -e RunningCI \
    -e ASAN_OPTIONS \
    -e TSAN_OPTIONS \
    -e UBSAN_OPTIONS \
    "$Image" $Setarch bash /Run_Linux_Tests.sh --inside-container
  exit 0
fi

# Run the tests natively on the runner

# To reproduce bug where getgrnam_r returns errors when user is not found
sudo apt update
sudo apt install sssd

if ! ConfigurePostgresPath; then
  sudo apt install --yes postgresql
fi

pwd
loginctl enable-linger runner
sleep 1
echo $XDG_RUNTIME_DIR
export XDG_RUNTIME_DIR=/run/user/$UID
echo $XDG_RUNTIME_DIR
env
ps aux --forest
systemctl status || true
sudo rm -rf /Deploy
sudo mkdir -p /Deploy
sudo chown $USER /Deploy

ArtifactsPath="$PWD/Artifacts/Deploy.tar.zst"
TestsOwner=
UserRun=()
SuperUserRun=(sudo -E)
ExtractAndRunTests
