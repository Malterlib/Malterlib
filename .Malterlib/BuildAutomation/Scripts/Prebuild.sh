#!/bin/bash
# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# PreStage entry point. The coordinator only syncs the top-level repository, so first synchronize the
# sub-repositories, then run the shared pre-build preparation (which lives in the Malterlib/Core sub-repository)
# with the given parameters.

set -e

if [ -x mib ]; then
	./mib update-repos
fi

./Malterlib/Core/BuildScripts/Prebuild.sh "$@"
