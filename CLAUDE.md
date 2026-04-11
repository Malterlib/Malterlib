# AI instructions

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

Git worktrees are supported by `mib`, but avoid them for agent-driven workflows in this repository. The codebase is organized as sub-repositories under `Malterlib/`, so agent edits often land inside those sub-repositories and later sync or publish steps from the top-level worktree will not behave correctly. Detached `HEAD` checkouts are also unsupported for bootstrap and `./mib update-repos`, because sub-repositories are synchronized against named branches.

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
