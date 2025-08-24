# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Malterlib3 is a comprehensive C++ framework and build system that provides cross-platform development tools, libraries, and applications. The project uses a custom build system called MTool/mib (Malterlib Build) with its own DSL for describing build configurations.

## Build System

### Core Build Tool
- **mib** - The main build command located at `./mib` (shell script wrapper)
- Uses custom `.MHeader`, `.MTarget`, `.MBuildSystem`, `.MRepo` files for configuration
- Supports multiple platforms: macOS, Windows, Linux
- Supports multiple architectures: x86_64, ARM64

### Common Build Commands

```bash
# Generate build system for a workspace
./mib generate [WorkspaceName]

# Build a workspace
./mib build [WorkspaceName] [Platform] [Architecture] [Configuration]
# Example: ./mib build Tests macOS x86_64 Debug

# Build a specific target within a workspace
./mib build_target [WorkspaceName] [TargetName] [Platform] [Architecture] [Configuration]

# Build and run tests
./mib test [Configuration]  # Default is Debug
./mib test_release          # Run tests with Release configuration

# Update repositories
./mib update_repos

# Get repository status
./mib status

# Setup prerequisites (macOS only)
./mib setup

# Run git commands across all repositories
./mib git [GitCommand] [Parameters]

# Checkout a branch across all repositories
./mib branch [BranchName]

# Push changes across all repositories
./mib push

# Clean up branches that have been pushed
./mib cleanup-branches [BranchNames...]

# Run a specific test
/opt/Deploy/Tests/RunAllTests --paths '["Path/To/Test", "Path/To/Test2", "Path/To/Test*"]' # macOS
/Deploy/Tests/RunAllTests --paths '["Path/To/Test", "Path/To/Test2", "Path/To/Test*"]' # Linux
/c/Tests/RunAllTests --paths '["Path/To/Test", "Path/To/Test2", "Path/To/Test*"]' # Windows

# Run tests with quiet output (only show failures)
/opt/Deploy/Tests/RunAllTests --quiet

# Get help for mib commands
./mib --help
./mib --help [CommandName]  # Detailed help for specific command
```

### Build Configurations
- **Debug** - Debug build with assertions and debug symbols
- **Release** - Optimized release build
- **Release (Tests)** - Release build with test support

## Architecture

### Module Organization
The codebase is organized into modules under the `Malterlib/` directory. Each module may contain its own CLAUDE.md file with module-specific guidance:

- **Core** - Core functionality, build system, and bootstrapping
- **Algorithm** - Algorithm implementations
- **Atomic** - Atomic operations
- **BuildSystem** - Build system components
- **Cloud** - Cloud services and applications
- **CommandLine** - Command-line parsing
- **Compression** - Compression libraries
- **Concurrency** - Threading and async operations
- **Container** - Data containers
- **Cryptography** - Cryptographic functions
- **Database** - Database interfaces
- **Debug** - Debugging tools
- **Encoding** - Text encoding utilities
- **File** - File system operations
- **Git** - Git integration
- **Graphics** - Graphics libraries
- **Memory** - Memory management
- **Mongo** - MongoDB integration
- **Network** - Networking
- **Process** - Process management
- **String** - String utilities
- **Test** - Testing framework
- **Thread** - Threading primitives
- **Tool** - Build and development tools
- **Web** - Web server and HTTP
- **WebApp** - Web application framework

### External Dependencies
Located in `External/` directory:
- boost
- CMake
- curl
- libarchive
- LLVM
- MariaDB connector
- MongoDB drivers
- nginx
- Node.js
- Qt
- SQLite
- zlib

### Build System Files
- **.MBuildSystem** - Root build system configuration
- **.MHeader** - Module header files defining targets and properties
- **.MTarget** - Target definitions
- **.MRepo** - Repository configuration
- **.MSettings** - Settings files

## Development Workflow

### Adding New Code
1. Place code in appropriate module directory under `Malterlib/`
2. Update or create `.MHeader` files to include new targets
3. Run `./mib generate` to regenerate build files
4. Build with `./mib build [workspace]`

### Running Tests
1. Generate test workspace: `./mib generate Tests`
2. Build tests: `./mib build Tests [Platform] [Architecture] Debug`
3. Run tests: `./mib test` or directly execute `RunAllTests` binary
4. To run specific tests: `/opt/Deploy/Tests/RunAllTests --paths '["Module/Test/Name"]'`
5. For continuous testing during development: build with Debug configuration for faster iteration

### Repository Management
- Check status: `./mib status`
- Update all repos: `./mib update_repos`
- Switch branch: `./mib branch [BranchName]`
- Push changes: `./mib push`
- The system uses git LFS for binary dependencies - ensure it's installed

### Working with Workspaces
Workspaces are collections of build targets. Common workspaces include:
- **Tests** - All test targets
- **MTool** - Build system tools
- **Malterlib_[Module]** - Specific module workspaces
- **Apps_Malterlib_[Module]** - Application workspaces

Generate a workspace before building: `./mib generate [WorkspaceName]`

## Code Standards

### Formatting Rules

#### Indentation
- Use 1 tab character for indentation (tab width = 4 columns)
- Do not expand tabs to spaces
- Tabs are preferred for easier navigation

#### Line Length
- Maximum 190 columns
- Designed to fit on screens down to 1280x720 resolution
- Allows side-by-side code viewing on wider screens

#### Whitespace and Operators
- Most operators have spaces before and after (except `.`, `->`, `*`)
- Comma operator has a space after, but not before
- Example: `int a = b * c;`

#### Braces and Blocks
- Opening brace `{` starts on a new line under the associated keyword
- Closing brace `}` is at the same indent level as the start
- Single statements do not require braces
- Space between keyword and parenthesis

#### Statement Splitting
- Each substatement on the same logical level goes on its own line
- Scope markers must be on separate lines
- Complex statements should be broken down for readability

### Naming Conventions

#### General Rules
- Use Upper Camel Case for most names
- Exceptions: Language functionality emulation uses lower case (e.g., `inline_always`, `uint32`)

#### Function Prefixes
- `f_`: Member function
- `fp_`: Private/protected member function
- `fs_`: Static member function
- `fsp_`: Private/protected static member function
- `fg_`: Global function
- `fsg_`: Static global function

#### Parameter Prefixes
- `_`: Standard function parameter
- `p_`: Function parameter pack
- `o_`: Output parameter
- `po_`: Output parameter pack
- `t_`: Template parameter
- `tp_`: Template parameter pack
- `d_`: Macro parameter

#### Variable Prefixes
- No prefix for local variables
- `c_`: Compile-time constant local variables
- `s_`: Static local variables
- `g_`: Global variables
- `gc_`: Compile-time constant global variables
- `gs_`: Static global variables
- `m_`: Member variables
- `mc_`: Compile-time constant member variables
- `ms_`: Static member variables
- `mp_`: Private/protected member variables

#### Type Prefixes
- `E`: Enums and enumerators
- `N`: Namespaces
- `C`: Classes, structs, typedefs
- `IC`: Interface classes
- `F`: Function types
- `TC`: Template classes
- `TIC`: Template interface classes
- `c`: Concepts

#### Conceptual Prefixes (after storage prefix)
- `b`: Boolean
- `i`: Iterator or index
- `n`: Number of
- `p`: Pointer
- `f`: Function object
- `r`: Range

## Important Notes

- The build system uses absolute paths by default
- Build artifacts are placed in `/opt/Deploy/`, `/Deploy/` or `/c/Deploy/` depending on the OS and `BuildSystem/Default/PostCopy.MConfig`
- The system supports cross-compilation for multiple platforms
- Use `./mib --help` for detailed command information
- The project uses custom memory management with configurable allocators
- LFS (Large File Storage) is used for binary dependencies
- The build system caches environment and dependency information in `BuildSystem/Default/`
- When switching branches, run `./mib update_repos` to ensure all repositories are synchronized
- The mib script automatically bootstraps required tools on first use
