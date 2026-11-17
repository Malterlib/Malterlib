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
  local Executable="p4d"
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)
      Platform=linux26x86_64
      ;;
    Linux-aarch64)
      Platform=linux26aarch64
      ;;
    Darwin-arm64)
      Platform=macosx12arm64
      ;;
    Darwin-x86_64)
      Platform=macosx1015x86_64
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Also for the x86 tests' x64 runners and Windows on arm64's x64 emulation
      Platform=ntx64
      Executable="p4d.exe"
      ;;
  esac

  if [[ -z "$Platform" ]]; then
    echo "Perforce ships no p4d for $(uname -s) $(uname -m), so the tests that need a Perforce server are skipped"
    return 0
  fi

  # Perforce replaces the binaries of a release with each of its patches, so p4d is checked against the checksum
  # Perforce publishes beside it, which tells a download that is cut short or mixed up, not who published it.
  local Url="https://ftp.perforce.com/perforce/$P4dRelease/bin.$Platform"
  local Download
  Download="$(mktemp)"

  local Checksum=""
  local Actual=""
  local Attempt
  for Attempt in 1 2 3; do
    # The executable's line of SHA256SUMS, as '<checksum> *<name>'
    Checksum="$(curl --fail --silent --show-error --location --retry 3 "$Url/SHA256SUMS" \
      | awk -v Name="$Executable" '{ sub(/\r$/, "") } !Found && ($2 == Name || $2 == "*" Name) { print $1; Found = 1 }')" || true
    curl --fail --silent --show-error --location --retry 3 --output "$Download" "$Url/$Executable" || true

    if command -v sha256sum >/dev/null 2>&1; then
      Actual="$(sha256sum "$Download" | cut -d ' ' -f 1)"
    else
      Actual="$(shasum -a 256 "$Download" | cut -d ' ' -f 1)"
    fi
    if [[ -n "$Checksum" && "$Actual" == "$Checksum" ]]; then
      break
    fi

    # A patch published between the two downloads gives the checksum of one and the binary of the other
    sleep 10
  done
  if [[ -z "$Checksum" || "$Actual" != "$Checksum" ]]; then
    echo "The SHA-256 of p4d $P4dRelease for $Platform is $Actual, and Perforce publishes '$Checksum'" >&2
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
