# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set -ex

source "$(dirname "${BASH_SOURCE[0]}")/Prepare_Repositories.sh"

# The builds run the same checks through the plugin in the Malterlib clang, but they only build the Tests workspace. This also
# checks the sources only the other workspaces build, for which they all need to be generated with their compile commands.
export MalterlibGenerateCompileCommands=true

echo ${SECONDS}s
./mib generate

echo ${SECONDS}s
./mib tidy --sorted
echo ${SECONDS}s
