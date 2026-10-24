# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set -e -o pipefail

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

# Prints the load of the machine every 5 minutes, so a slow run shows whether the runner was starved
StartLoadMonitor() {
  (
    read -r _ User Nice System Idle IOWait IRQ SoftIRQ Steal _ < /proc/stat
    while sleep 300; do
      read -r _ NewUser NewNice NewSystem NewIdle NewIOWait NewIRQ NewSoftIRQ NewSteal _ < /proc/stat
      local Total=$(( (NewUser + NewNice + NewSystem + NewIdle + NewIOWait + NewIRQ + NewSoftIRQ + NewSteal) - (User + Nice + System + Idle + IOWait + IRQ + SoftIRQ + Steal) ))
      if (( Total > 0 )); then
        local Busy=$(( 100 * ((NewUser + NewNice + NewSystem + NewIRQ + NewSoftIRQ) - (User + Nice + System + IRQ + SoftIRQ)) / Total ))
        local IOWaitPercent=$(( 100 * (NewIOWait - IOWait) / Total ))
        local StealPercent=$(( 100 * (NewSteal - Steal) / Total ))
        local Memory
        Memory="$(awk '/^(MemAvailable|SwapTotal|SwapFree):/ { printf " %s %d MiB", $1, $2 / 1024 }' /proc/meminfo)"
        echo "Load $(date -u +%H:%M:%S): average $(cut -d ' ' -f 1-3 /proc/loadavg), busy ${Busy}%, iowait ${IOWaitPercent}%, steal ${StealPercent}%,${Memory}"
      fi
      User=$NewUser Nice=$NewNice System=$NewSystem Idle=$NewIdle IOWait=$NewIOWait IRQ=$NewIRQ SoftIRQ=$NewSoftIRQ Steal=$NewSteal
    done
  ) &
  LoadMonitorPID=$!
  trap 'kill "$LoadMonitorPID" 2>/dev/null || true' EXIT
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
  # The deploy artifact carries LLDB from our LLVM build, see Build.sh
  export MalterlibStackLLDB=/Deploy/LLDB/bin/lldb
  "$MalterlibStackLLDB" --version
  if [[ -n "${TestsOwner:-}" ]]; then
    chown -R "$TestsOwner" /Deploy
  fi

  cd Tests
  StartLoadMonitor
  # Apply the limit after user switching; the test processes inherit it for rings and pinned send buffers.
  local TestRun=(prlimit --memlock=unlimited:unlimited -- ./RunAllTests)
  "${UserRun[@]}" "${TestRun[@]}" --quiet --launch-per-suite --suite-order slow_first --timeout 3600 -- --logs --log-concurrency-shutdown
  "${SuperUserRun[@]}" "${TestRun[@]}" -g SuperUser --quiet --launch-per-suite --suite-order slow_first --timeout 3600 --no-parallel -- --logs --log-concurrency-shutdown
}

if [[ "${1:-}" == "--inside-container" ]]; then
  export LANG=C.UTF-8

  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install --yes --no-install-recommends ca-certificates git zstd postgresql nodejs npm util-linux passwd gdb
  elif command -v dnf >/dev/null 2>&1; then
    dnf install --assumeyes ca-certificates git zstd tar postgresql-server nodejs npm util-linux shadow-utils gdb
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Syu --noconfirm ca-certificates git zstd postgresql nodejs npm util-linux shadow gdb
  elif command -v zypper >/dev/null 2>&1; then
    zypper --non-interactive install ca-certificates git zstd tar gzip findutils postgresql-server nodejs-default npm-default util-linux shadow gdb
  else
    echo "No supported package manager found" >&2
    exit 1
  fi

  if ! grep -q '^::1' /etc/hosts; then
    echo '::1 localhost ip6-localhost ip6-loopback' >> /etc/hosts
  fi

  useradd -m tester

  # RunAllTests keeps the suite runtimes it orders suites by in the home directory, and the workflow caches them between runs
  chown -R tester /TestRuntimes
  for MalterlibHome in /home/tester/.Malterlib /root/.Malterlib; do
    mkdir -p "$MalterlibHome"
    ln -sfn /TestRuntimes "$MalterlibHome/TestRuntimes"
  done
  chown -h tester /home/tester/.Malterlib /home/tester/.Malterlib/TestRuntimes

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
  mkdir -p "$PWD/CrashDumps"
  mkdir -p "$HOME/.Malterlib/TestRuntimes"
  docker run --rm --init \
    --network malterlib-tests \
    --shm-size=1g \
    --ulimit memlock=-1:-1 \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    "${DockerArgs[@]}" \
    -v "$PWD/Artifacts:/Artifacts:ro" \
    -v "$PWD/CrashDumps:/Deploy/CrashDumps" \
    -v "$HOME/.Malterlib/TestRuntimes:/TestRuntimes" \
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

# Raise this shell's hard limit so ordinary test processes can retain it without running as root.
sudo prlimit --pid "$BASHPID" --memlock=unlimited:unlimited
prlimit --pid "$BASHPID" --memlock

# To reproduce bug where getgrnam_r returns errors when user is not found
sudo apt update
sudo apt install sssd

# RunAllTests falls back to gdb when LLDB cannot print the stacks of a suite that hangs
sudo apt install --yes gdb

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
