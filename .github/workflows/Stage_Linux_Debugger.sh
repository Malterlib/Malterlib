# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set -euo pipefail

# Copies LLDB from our LLVM build for RunAllTests to print the stacks of hung suites with.
# LLDB reads the zstd compressed debug sections that the gdb of some distributions cannot.
# Usage: Stage_Linux_Debugger.sh <LLVM binaries directory> <destination directory>

LLVMDirectory="$1"
Destination="$2"

for File in bin/lldb bin/lldb-server; do
	if [[ ! -f "$LLVMDirectory/$File" ]]; then
		echo "$LLVMDirectory/$File was not found" >&2
		exit 1
	fi
done

mkdir -p "$Destination"
Destination="$(realpath "$Destination")"

cd "$LLVMDirectory"

shopt -s nullglob
Files=(
	bin/lldb
	bin/lldb-server
	lib/liblldb.so*
	lib/libc++.so*
	lib/libc++abi.so*
	lib/libunwind.so*
	lib/*-unknown-linux-gnu/libc++.so*
	lib/*-unknown-linux-gnu/libc++abi.so*
	lib/*-unknown-linux-gnu/libunwind.so*
)
shopt -u nullglob

tar -cf - "${Files[@]}" | tar -xf - -C "$Destination"
