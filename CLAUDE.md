# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Malterlib Framework Documentation

**For comprehensive framework documentation, coding standards, and module references, see:**
@Malterlib/Core/CLAUDE.md

The Core module documentation serves as the central reference point for:
- Complete framework overview and architecture
- Build system usage and commands
- Coding standards and naming conventions
- Development workflow guidelines
- Links to all module-specific CLAUDE.md files

## Repository-Specific Information

**Do not use git worktrees** in this repository. The codebase is organized as sub-repositories under `Malterlib/`, and worktrees do not work correctly with this structure.

This repository contains the complete Malterlib framework source code, organized as follows:

### Directory Structure
- `Malterlib/` - All framework modules
- `External/` - Third-party dependencies
- `BuildSystem/` - Build system configuration
- `./mib` - Main build command

### Quick Start
```bash
# Setup (macOS only)
./mib setup

# Build and run tests
MalterlibBuildShowProgress=false ./mib test

# Get help
./mib --help
```

## For External Projects

When using Malterlib in external projects, reference:
- `Malterlib/Core/CLAUDE.md` - Complete framework documentation and all module links

This single reference provides access to the entire documentation hierarchy.
