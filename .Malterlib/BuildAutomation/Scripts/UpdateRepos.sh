#!/bin/bash
# Copyright © Unbroken AB
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Synchronizes the sub-repositories of a fresh or re-synced checkout. Runs as the PreStage so that the build scripts
# under Malterlib/ exist before any build command needs them.

set -e

if [ -x mib ]; then
	./mib update-repos
fi
