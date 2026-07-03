# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set -e

ConfigurePostgresPath() {
  while IFS= read -r PostgresBin; do
    if [[ -n "$PostgresBin" && -x "$PostgresBin/initdb.exe" && -x "$PostgresBin/pg_ctl.exe" ]]; then
      export PGBIN="$(cygpath -w "$PostgresBin")"
      export PATH="$PostgresBin:$PATH"
      "$PostgresBin/initdb.exe" --version
      "$PostgresBin/pg_ctl.exe" --version
      return 0
    fi
  done < <(printf '%s\n' "/c/Program Files/PostgreSQL"/*/bin "$RUNNER_TEMP/postgresql-binaries"/*/bin "$PGBIN" | sort -Vr)

  return 1
}

if ! ConfigurePostgresPath; then
  PostgresArchive="$RUNNER_TEMP/postgresql-binaries.zip"
  PostgresRoot="$RUNNER_TEMP/postgresql-binaries"
  curl --fail --location --output "$PostgresArchive" "https://get.enterprisedb.com/postgresql/postgresql-18.4-1-windows-x64-binaries.zip"
  rm -rf "$PostgresRoot"
  mkdir -p "$PostgresRoot"
  powershell -NoProfile -Command "Expand-Archive -LiteralPath '$PostgresArchive' -DestinationPath '$PostgresRoot' -Force"

  if ! ConfigurePostgresPath; then
    echo "PostgreSQL initdb.exe and pg_ctl.exe were not found" >&2
    exit 1
  fi
fi

set -x
if [[ "$MatrixOs" == "windows-2019" ]]; then
  MalterlibFlakySuites="$MalterlibFlakySuites;Malterlib/Cloud/SecretsManager/General"
fi
pwd
echo Num CPU threads: `getconf _NPROCESSORS_ONLN`
rm -rf Deploy
mkdir -p Deploy
cd Deploy
export MalterlibCrashDumpDir=`cygpath -m "$PWD/CrashDumps"`
mkdir -p "$PWD/CrashDumps"
BsdTar="../Artifacts/bsdtar.exe"
if [[ ! -f "$BsdTar" ]]; then
  BsdTar="tar"
fi
"$BsdTar" -xf ../Artifacts/Deploy.tar.zst
cd Tests*
./RunAllTests --quiet --launch-per-suite --suite-order slow_first --timeout 3600 -- --logs
