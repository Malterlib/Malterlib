# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Installs p4d for the tests that use CPerforceTestServer. Where Perforce ships no p4d, those tests report a skip.
#
# InstallP4d <directory to install into> [sudo]

P4dRelease=r26.1

InstallP4d() {
  local InstallDirectory="$1"
  local Sudo="${2:-}"

  local Platform=""
  local Checksum=""
  local Executable="p4d"
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)
      Platform=linux26x86_64
      Checksum=e2c1e11865774782eb37483c0a6f6ebdfc09d9dca6f44880ae59059cdf7b1847
      ;;
    Linux-aarch64)
      Platform=linux26aarch64
      Checksum=8f90d82e4a8cf873db2c0341075d57bd9f34a2d094133a657d1682d487917584
      ;;
    Darwin-arm64)
      Platform=macosx12arm64
      Checksum=fd125175d1a2f5e22f97aa842a65a81d5dedfd417b98cac7833f3b7302ffe3ba
      ;;
    Darwin-x86_64)
      Platform=macosx1015x86_64
      Checksum=2044e69cf81e6991dfa0a2c0b590e9e082ead2d345d6c05cf3446678e5ce3022
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Also for the x86 tests' x64 runners and Windows on arm64's x64 emulation
      Platform=ntx64
      Checksum=eee7ac13927872282bcb3e4b037af960f2ec0905a1e6747cb343e77ac1e7091d
      Executable="p4d.exe"
      ;;
  esac

  if [[ -z "$Platform" ]]; then
    echo "Perforce ships no p4d for $(uname -s) $(uname -m), so the tests that need a Perforce server are skipped"
    return 0
  fi

  local Download
  Download="$(mktemp)"
  curl --fail --silent --show-error --location --retry 3 --output "$Download" "https://ftp.perforce.com/perforce/$P4dRelease/bin.$Platform/$Executable"

  local Actual
  if command -v sha256sum >/dev/null 2>&1; then
    Actual="$(sha256sum "$Download" | cut -d ' ' -f 1)"
  else
    Actual="$(shasum -a 256 "$Download" | cut -d ' ' -f 1)"
  fi
  if [[ "$Actual" != "$Checksum" ]]; then
    echo "The SHA-256 of p4d $P4dRelease for $Platform is $Actual, expected $Checksum" >&2
    rm -f "$Download"
    return 1
  fi

  $Sudo mkdir -p "$InstallDirectory"
  $Sudo install -m 755 "$Download" "$InstallDirectory/$Executable"
  rm -f "$Download"

  case ":$PATH:" in
    *":$InstallDirectory:"*) ;;
    *) export PATH="$InstallDirectory:$PATH" ;;
  esac

  echo "Installed p4d $P4dRelease for $Platform in $InstallDirectory"
}
