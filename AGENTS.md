<!-- GENERATED FILE: Do not edit manually. Run ./Malterlib/Core/Tools/generate_agents.py to regenerate. -->

<!-- Begin include: CLAUDE.md -->
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Malterlib Framework Documentation

**For comprehensive framework documentation, coding standards, and module references, see:**
@Malterlib/Core/CLAUDE.md  (see below)

The Core module documentation serves as the central reference point for:
- Complete framework overview and architecture
- Build system usage and commands
- Coding standards and naming conventions
- Development workflow guidelines
- Links to all module-specific CLAUDE.md files

## Repository-Specific Information

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

# Build tests
./mib generate Tests
MalterlibBuildShowProgress=false ./mib build Tests macOS arm64 Debug
./mib test

# Get help
./mib --help
```

## For External Projects

When using Malterlib in external projects, reference:
- `Malterlib/Core/CLAUDE.md` - Complete framework documentation and all module links

This single reference provides access to the entire documentation hierarchy.
<!-- Begin include: Malterlib/Core/CLAUDE.md -->
# CLAUDE.md - Malterlib Framework and Core Module

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with the Malterlib framework. Since the Core module is the foundation of the entire Malterlib framework, this document contains both general framework guidelines and Core module-specific information.

## Malterlib Framework Overview

Malterlib is a comprehensive C++ framework and build system that provides cross-platform development tools, libraries, and applications. The project uses a custom build system called MTool/mib (Malterlib Build) with its own DSL for describing build configurations.

## Build System

### Core Build Tool
- **mib** - The main build command located at `./mib` (shell script wrapper)
- Uses custom `.MHeader`, `.MTarget`, `.MBuildSystem`, `.MRepo` files for configuration
- Supports multiple platforms: macOS, Windows, Linux
- Supports multiple architectures: arm64, x86, x86

### Common Build Commands

```bash
# Generate build system for a workspace
./mib generate [WorkspaceName]

# Build a workspace
MalterlibBuildShowProgress=false ./mib build [WorkspaceName] [Platform] [Architecture] [Configuration]
# Example: ./mib build Tests macOS arm64 Debug

# Build a specific target within a workspace
MalterlibBuildShowProgress=false ./mib build_target [WorkspaceName] [TargetName] [Platform] [Architecture] [Configuration]
# Example: ./mib build Tests Com_Test_Malterlib_Container macOS arm64 Debug

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

Remember to use MalterlibBuildShowProgress=false when building so you don't get overwhelmed with uncessary output.

### Build Configurations
- **Debug** - Debug build with assertions and debug symbols
- **Release** - Optimized release build
- **Release (Tests)** - Release build with test support

### Build Platforms
- **Windows** - Buildable on Windows host
- **macOS** - Buildable on macOS host
- **Linux** - Buildable on macOS host

### Build Configurations
- **arm64** - Supported on macOS, Linux and Windows
- **x64** - Supported on macOS, Linux and Windows
- **x86** - Only supported on Linux

## Framework Architecture

### Module Organization
The codebase is organized into modules under the `Malterlib/` directory. Each module may contain its own CLAUDE.md file with module-specific guidance - see the [Related Module Documentation](#related-module-documentation) section below for links.

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
4. Build with `MalterlibBuildShowProgress=false ./mib build [workspace]`

### Running Tests
1. Generate test workspace: `./mib generate Tests`
2. Build tests: `MalterlibBuildShowProgress=false ./mib build Tests [Platform] [Architecture] Debug`
3. Run tests: `./mib test` or directly execute `RunAllTests` binary
4. To run specific tests: `/opt/Deploy/Tests/RunAllTests --paths '["Module/Test/Name"]'`
5. For continuous testing during development: build with Debug configuration for faster iteration

### Repository Management
- Check status: `./mib status`
- Update all repos: `./mib update_repos`
- Switch branch: `./mib branch [BranchName]`
- Push changes: `./mib push`
- The system uses git LFS for binary dependencies - ensure it's installed
- Many directories under `Malterlib/` are separate Git repositories. When checking status or searching history, run Git commands inside the relevant subdirectory (`Malterlib/Concurrency`, `Malterlib/Cloud`, etc.) or use the helper scripts (`./mib git ...`) that fan out across sub-repos.

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
- **All files in `Malterlib/` use tabs** - when editing, always assume that the file has tabs, unless you know different
- Files in `External/` (third-party code) may use different conventions - check the specific file

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

## Important Framework Notes

- The build system uses absolute paths by default
- Build artifacts are placed in `/opt/Deploy/`, `/Deploy/` or `/c/Deploy/` depending on the OS and `BuildSystem/Default/PostCopy.MConfig`
- The system supports cross-compilation for multiple platforms
- Use `./mib --help` for detailed command information
- The project uses custom memory management with configurable allocators
- LFS (Large File Storage) is used for binary dependencies
- The build system caches environment and dependency information in `BuildSystem/Default/`
- When switching branches, run `./mib update_repos` to ensure all repositories are synchronized
- The mib script automatically bootstraps required tools on first use

## Core Module Overview

The Core module provides:
- **Platform Abstraction Layer** - Cross-platform support for macOS, Windows, Linux
- **Build System Components** - mib (Malterlib Build) system configuration and generators
- **Application Framework** - Base application class and entry point management
- **Subsystem Management** - Lazy initialization and lifecycle management
- **Runtime Type System** - RTTI and dynamic type identification
- **Platform Detection** - Compile-time and runtime platform detection
- **Core Utilities** - Scope guards, enum operators, type traits

## Directory Structure

```
Core/
├── Build/               # Build system configurations
│   ├── Clang/          # Clang-specific settings
│   ├── VisualStudio/   # Visual Studio generators
│   └── Xcode/          # Xcode generators
├── BuildScripts/       # Platform-specific build scripts
├── Documentation/      # Module documentation
├── Export/             # Export configurations per language
├── Include/Mib/Core/   # Public headers
├── Source/             # Implementation files
│   └── Platform/       # Platform-specific implementations
├── Test/               # Module tests
└── Tools/              # Core tools and utilities
```

## Key Components

### Application Framework

The application framework provides the main entry point abstraction:

```cpp
// Application implementation example
namespace NAppName
{
	class CMyApp : public NMib::CApplication
	{
	public:
		virtual aint f_Main() override
		{
			// Application logic here
			return 0;
		}
	};
}

// Register the application
DAppImplement(CMyApp)
```

### Subsystem Management

Subsystems provide lazy initialization with guaranteed destruction order useful for functionality that should outlive the main function:

```cpp
// Define a subsystem
class CMySubSystem
{
public:
	void f_Initialize()
	{
		// Initialization code
	}

	void f_DoWork()
	{
		// Subsystem functionality
	}
};

// Declare the subsystem with destruction order
namespace NMib
{
	extern TCSubSystem<CMySubSystem, ESubSystemDestruction::EAfterMain> g_MySubSystem;
}

// Use the subsystem (lazy initialized on first access)
void fg_UseSubSystem()
{
	NMib::g_MySubSystem->f_DoWork();
}
```

### Platform Detection

Platform detection happens at compile-time through macros:

```cpp
// Platform family detection
#ifdef DMibPlatformFamily_macOS
	// macOS-specific code
#elif DMibPlatformFamily_Windows
	// Windows-specific code
#elif DMibPlatformFamily_Linux
	// Linux-specific code
#endif

// Architecture detection
#ifdef DMibArchitecture_x64
	// x86_64-specific code
#elif DMibArchitecture_arm64
	// ARM64-specific code
#endif

// Compiler detection
#ifdef DMibCompiler_MSVC
	// MSVC-specific code
#elif DMibCompiler_Clang
	// Clang-specific code
#endif
```

### Scope Guards

RAII-based scope guards for cleanup:

```cpp
void fg_Example()
{
	FILE *pFile = fopen("test.txt", "r");

	// Ensure file is closed on scope exit
	auto Cleanup = NMib::g_OnScopeExit / [&]
		{
			if (pFile)
				fclose(pFile);
		}
	;

	// Use file...
	// File automatically closed when scope exits
}

// Conditional cleanup - can clear the scope guard
void fg_ConditionalCleanup()
{
	bool bSuccess = false;
	auto Cleanup = NMib::g_OnScopeExit / [&]
		{
			if (!bSuccess)
				f_PerformRollback();
		}
	;

	// Do work...
	if (fg_OperationSucceeded())
	{
		bSuccess = true;
		Cleanup.f_Clear();  // Cancel the cleanup
	}
}

// Exception-safe cleanup
void fg_ExceptionSafeCleanup()
{
	auto Cleanup = NMib::g_OnScopeExitCatch / [&]
		{
			// This runs even if an exception is thrown
			// and catches any exceptions from the cleanup itself
			f_PerformCleanup();
		}
	;

	// Do work that might throw...
}
```

### Runtime Type System

Runtime type identification and class registration:

```cpp
// Define a runtime class
class CMyClass : public NMib::CRuntimeClass
{
	DMibRuntimeClass(NMib::CRuntimeClass, CMyClass);

public:
	void f_DoSomething()
	{
		// Implementation
	}
};

// Use runtime type checking
void fg_ProcessObject(NMib::CRuntimeClass *_pObject)
{
	if (CMyClass *pMyClass = DMibDynamicCast<CMyClass>(_pObject))
		pMyClass->f_DoSomething();
}
```

### Enum Operators

Type-safe enum class operators:

```cpp
// Define an enum with operators
enum class EMyFlags : uint32
{
	ENone = 0,
	EFlag1 = 1 << 0,
	EFlag2 = 1 << 1,
	EFlag3 = 1 << 2
};
DMibEnumOperators(EMyFlags);

// Use enum operators
void fg_UseFlags()
{
	EMyFlags nFlags = EMyFlags::EFlag1 | EMyFlags::EFlag2;

	if (nFlags & EMyFlags::EFlag1)
	{
		// Flag1 is set
		fg_ProcessFlag1();
	}

	nFlags &= ~EMyFlags::EFlag2;  // Clear Flag2
}
```

## Platform-Specific Implementation

### File Organization

Platform-specific code uses different file extensions for different purposes:

**Implementation Files (.cpp)**
- `Malterlib_Core_PlatformImp_MSVC.cpp` - Windows/MSVC implementation
- `Malterlib_Core_PlatformImp_MacOS.cpp` - macOS implementation
- `Malterlib_Core_PlatformImp_Linux.cpp` - Linux implementation
- `Malterlib_Core_PlatformImp_Posix_Init.cpp` - Shared POSIX initialization
- `Malterlib_Core_Platform_Windows_*.cpp` - Windows-specific features
- `Malterlib_Core_Platform_MacOS_*.cpp` - macOS-specific features
- `Malterlib_Core_Platform_POSIX_*.cpp` - POSIX-specific features

**Implementation Headers (.imp.h)**
- `Malterlib_Core_PlatformImp_POSIX.imp.h` - POSIX implementation templates
- `Malterlib_Core_PlatformImp_*_Net.imp.h` - Network implementations
- `Malterlib_Core_PlatformImp.imp.h` - Core platform implementation

**Header Templates (.hpp)**
- `Malterlib_Core_PlatformImp_POSIX_*.hpp` - POSIX template implementations
- `Malterlib_Core_Platform_*_*.hpp` - Platform-specific templates

## Build System Integration

### MHeader Files

The Core module uses several .MHeader files:
- `Malterlib_Core.MHeader` - Main module configuration
- `Malterlib_Core_Modules.MHeader` - Module dependencies
- `Malterlib_Core_boost.MHeader` - Boost integration
- `Malterlib_Core_Export.MHeader` - Export settings

### Build Configurations

Build settings are organized hierarchically:
- `Shared.MSettings` - Base settings for all platforms
- `Shared_Compile.MSettings` - Compilation settings
- `Shared_Dependencies.MSettings` - Dependency management
- `Shared_Target.MSettings` - Target configuration

### Generator Settings

Platform-specific generators:
- `VisualStudio.MGeneratorSettings` - Visual Studio project generation
- `Xcode.MGeneratorSettings` - Xcode project generation
- `Clang.MGeneratorSettings` - Clang compilation settings

## Dependencies

### Internal Dependencies

Core has minimal internal dependencies:
- **Memory** - Custom memory allocators (when MalterlibSubLibrarySeparate)
- **Thread** - Threading primitives (when MalterlibSubLibrarySeparate)
- **Atomic** - Atomic operations (when MalterlibSubLibrarySeparate)
- **String** - String utilities (when MalterlibSubLibrarySeparate)

### External Dependencies

Platform-specific system libraries:
- **macOS**: CoreFoundation, Security, AppKit, Cocoa, IOKit
- **Windows**: kernel32, user32, advapi32, shell32
- **Linux**: pthread, dl, rt

## Code Examples

### Creating a Simple Application

```cpp
// MyApp.cpp
#include <Mib/Core/Application>
#include <Mib/String/Str>

namespace NAppName
{
	class CMyApp : public NMib::CApplication
	{
	public:
		virtual aint f_Main() override
		{
			// Get command line parameters
			aint nNumParams = f_NumCommandLineParameters();
			for (aint i = 0; i < nNumParams; ++i)
			{
				NStr::CStr Param = f_CommandLineParameter(i);
				// Process parameter
			}

			// Application logic
			return 0;  // Success
		}
	};
}

// Register the application
DAppImplement(CMyApp)
```

### Platform-Specific Code

```cpp
// CrossPlatformFile.cpp
#include <Mib/Core/Platform>

void fg_CreateConfigDirectory()
{
	NStr::CStr Path;

#ifdef DMibPlatformFamily_Windows
	Path = NPlatform::fg_GetEnvironmentVariable("APPDATA");
	Path += "\\MyApp";
#elif DMibPlatformFamily_macOS
	Path = NPlatform::fg_GetHomeDirectory();
	Path += "/Library/Application Support/MyApp";
#elif DMibPlatformFamily_Linux
	Path = NPlatform::fg_GetHomeDirectory();
	Path += "/.config/myapp";
#endif

	if (!NPlatform::fg_DirectoryExists(Path))
		NPlatform::fg_CreateDirectory(Path);
}
```

### Using Subsystems

```cpp
// LoggingSubSystem.cpp
#include <Mib/Core/SubSystem>

class CLoggingSubSystem
{
public:
	CLoggingSubSystem()
	{
		// Constructor - called on first access
		fp_Initialize();
	}

	~CLoggingSubSystem()
	{
		// Destructor - called at program exit
		fp_Shutdown();
	}

	void f_Log(NStr::CStr const &_Message)
	{
		// Log message
	}

private:
	void fp_Initialize()
	{
		// Open log file, etc.
	}

	void fp_Shutdown()
	{
		// Close log file, flush buffers
	}
};

// Define global subsystem
namespace NMib
{
	constinit TCSubSystem<CLoggingSubSystem, ESubSystemDestruction::EBeforeMain> g_Logging;
}

// Use the subsystem
void fg_LogMessage(NStr::CStr const &_Message)
{
	NMib::g_Logging->f_Log(_Message);
}
```

## Testing

Core module tests are located in `Test/` directory:
- `Test_Malterlib_Core_Operators.cpp` - Operator overloading tests
- `Test_Malterlib_Core_Move.cpp` - Move semantics tests
- `Test_Malterlib_Core_StdLib.cpp` - Standard library compatibility
- `Test_Malterlib_Core_CodeFormatting.cpp` - Code formatting validation
- `Test_Malterlib_Core_CodeColoring.cpp` - Syntax highlighting tests

Run tests with:
```bash
/opt/Deploy/Tests/RunAllTests --paths '["Malterlib/Core/*"]'
# Or specific test
/opt/Deploy/Tests/RunAllTests --paths '["Malterlib/Core/Test/Operators"]'
```

## Important Notes

### Thread Safety
- Subsystems use spin locks for thread-safe lazy initialization
- Platform functions are generally thread-safe unless noted
- Application class is single-instance, not thread-safe

### Memory Management
- Core does not allocate heap memory during static initialization
- Subsystems are constructed with placement new with memory from the image
- Platform functions may allocate memory as needed

### Error Handling
- Platform functions typically return bool for success/failure
- Critical failures use exceptions

### Performance Considerations
- Subsystem access has one-time initialization cost
- Platform detection is compile-time (zero runtime cost)
- Scope guards have minimal overhead (optimized away in release)

## Common Patterns

### Singleton Pattern via Subsystems
```cpp
class CMySingleton
{
public:
	static CMySingleton &fs_Get()
	{
		return *NMib::g_MySingleton;
	}

	void f_DoWork();
};

namespace NMib
{
	constinit TCSubSystem<CMySingleton, ESubSystemDestruction::EAfterMain> g_MySingleton;
}
```

## Debugging Support

### Assertions
```cpp
// Debug assertions (removed in release)
DMibCheck(_pPointer != nullptr);
```

### Platform-Specific Debugging
```cpp
#ifdef DMibDebug
	// Debug-only code
	NPlatform::fg_DebugBreak();  // Trigger debugger
	NPlatform::fg_OutputDebugString("Debug message");
#endif
```

## Best Practices

1. **Always use platform abstraction** - Never use OS APIs directly
2. **Prefer subsystems over globals** - Use TCSubSystem for singletons
3. **Use scope guards for cleanup** - `g_OnScopeExit / [&]{}` for RAII
4. **Check platform at compile-time** - Use DMibPlatformFamily_* macros
5. **Follow naming conventions** - See main CLAUDE.md for standards
6. **Test on all platforms** - Core changes affect entire framework
7. **Document platform differences** - Note any platform-specific behavior
8. **Minimize dependencies** - Core should have minimal external dependencies

## Common Development Debugging Mistakes

Based on real development sessions, here are common mistakes to avoid when debugging Malterlib issues:

1. **Fix symptoms instead of root causes** - When functionality isn't working, analyze the underlying implementation rather than creating workarounds in application code.

2. **Add logging to wrong execution paths** - Use comprehensive diagnostic logging to understand which code paths are actually being taken before making assumptions about program flow.

3. **Treat all error conditions the same** - Different error codes often have different meanings. Only handle specific error conditions you can prove are the intended case, and report others as distinct error types.

4. **Use human-readable error messages** - Always use platform error translation functions (like `NPlatform::fg_Win32_GetLastErrorStr()`) instead of just showing numeric error codes to users or logs.

5. **Don't fix multiple C++ compilation errors simultaneously** - In C++, always fix the first compilation error first. Other errors often cascade from the initial issue and may resolve automatically once the first error is fixed. Attempting to fix multiple errors simultaneously can lead to confusion and wasted effort.

6. **Distinguish IDE diagnostics from manual build diagnostics** - When using the `mcp__ide__getDiagnostics` tool, diagnostics come from different sources:
   - **clangd diagnostics** (language server): Have `"source": "clang"` and `"code"` fields (e.g., `"code": "ovl_no_viable_oper"`). These are live and updated as you edit files - trust these for current file state. Also note that you cannot always trust the diagnostics in header files, because clangd doesn't always have the context correct.
   - **Manual build diagnostics**: Have NO `source` or `code` fields. These are stale results from a previous build the user ran manually and may not reflect current code state.

   **Best practice**: Ignore diagnostics without a `source` field unless the user explicitly says something like "check the last build I did" or "look at the build output". When in doubt, trust clangd diagnostics (those with `"source": "clang"`) as they reflect the current state of the code.

## Module-Specific Coding Standards

In addition to the general Malterlib coding standards:

1. **Platform code organization** - Platform-specific implementations go in Source/Platform/
2. **Export configurations** - Language-specific exports go in Export/
3. **Build system files** - Keep build configurations in Build/ directory
4. **Include guards** - Use `#pragma once` for all headers
5. **Inline directives** - Use `inline_always`, `inline_never` for optimization hints
6. **Debug markers** - Use `mark_nodebug` to exclude from debug builds

## Related Module Documentation

Since Core is the foundation of Malterlib, here are references to all module-specific CLAUDE.md files that provide detailed guidance for each module:

### Framework Modules
- **Container**: `@../Container/CLAUDE.md` (see below) - Data structures and containers
- **Concurrency**: `@../Concurrency/CLAUDE.md` (see below) - Async operations and parallel processing
- **Encoding**: `@../Encoding/CLAUDE.md` (see below) - Text encoding and character sets
- **Storage**: `@../Storage/CLAUDE.md` (see below) - Persistent storage abstractions
- **String**: `@../String/CLAUDE.md` (see below) - String operations and formatting

- **Atomic**: `../Atomic/CLAUDE.md` - Atomic operations and lock-free programming
- **BuildSystem**: `../BuildSystem/CLAUDE.md` - Build system components and mib tool
- **Cloud**: `../Cloud/CLAUDE.md` - Cloud services integration
- **Cryptography**: `../Cryptography/CLAUDE.md` - Cryptographic operations
- **Database**: `../Database/CLAUDE.md` - Database interfaces and abstractions
- **File**: `../File/CLAUDE.md` - File system operations
- **Function**: `../Function/CLAUDE.md` - Function utilities and delegates
- **Intrusive**: `../Intrusive/CLAUDE.md` - Intrusive data structures
- **Network**: `../Network/CLAUDE.md` - Networking and communication
- **Numeric**: `../Numeric/CLAUDE.md` - Numerical operations and math
- **Process**: `../Process/CLAUDE.md` - Process management and IPC
- **Stream**: `../Stream/CLAUDE.md` - Stream processing and I/O
- **Time**: `../Time/CLAUDE.md` - Time and date utilities
- **Web**: `../Web/CLAUDE.md` - Web server and HTTP handling


### Main Framework Documentation
- **Project Overview**: `../../CLAUDE.md` - Main project guidelines and standards

When working with any of these modules, refer to their specific CLAUDE.md files for module-specific patterns, best practices, and implementation details.

### Important Modules that should always be in context
@../String/CLAUDE.md  (see below)
@../Storage/CLAUDE.md  (see below)
@../Container/CLAUDE.md  (see below)
@../Encoding/CLAUDE.md  (see below)
@../Concurrency/CLAUDE.md  (see below)
<!-- Begin include: Malterlib/String/CLAUDE.md -->
# CLAUDE.md - String Module

## Module Overview

The String module provides comprehensive string handling capabilities for the Malterlib framework, supporting multiple character encodings (ANSI, UTF-8, UTF-16, UTF-32/Unicode) with efficient algorithms and flexible storage implementations. This module offers high-performance string operations, formatting, parsing, and Unicode support.

## Key Components

### Core String Types
- **CStr** - UTF-8 string (most common, default)
- **CStrAnsi** - ANSI/ASCII string (single-byte, no Unicode)
- **CWStr** - UTF-16 string (Windows wide string compatible)
- **CUStr** - UTF-32/Unicode string (full Unicode codepoint per character)
- **gc_Str** - Compile-time constant strings (constexpr)

### String Variants
- **NonTracked** variants - No memory tracking (e.g., `CStrNonTracked`)
- **Secure** variants - Secure memory wiping (e.g., `CStrSecure`)
- **VMem** variants - Virtual memory backed strings
- **Span** types - Non-owning string views (e.g., `CStrSpan`)

### Storage Implementations
- **Dynamic** (`TCStrImp_Dynamic`) - Heap-allocated, growable
- **Fixed** (`TCStrImp_Fixed`) - Stack-allocated, fixed size
- **Pointer** (`TCStrImp_Pointer`) - References external memory
- **Virtual** (`TCStrImp_Virtual`) - Abstract interface for custom storage

### Algorithms
Extensive algorithm library with modular design:
- **Text Operations**: Find, Replace, Split, Trim, Capitalize, Case conversion
- **Comparison**: Compare, StartsWith, EndsWith, WildcardMatch
- **Encoding**: UTF-8/16/32 conversion, ANSI conversion
- **Hashing**: DJB2, Murmur3, SDBM algorithms
- **Special**: FuzzyMatch, Escape (Bash), Sanitize

### Formatting & Parsing
- **Formatters**: Integer, Float, Binary, Time, String formatting
- **Parsers**: Integer, Float, String parsing with pattern matching
- **Format Utils**: Printf-style formatting with type safety

### Iterators
- **Character Iterators**: Navigate by characters/codepoints
- **Unicode Iterator**: Proper Unicode grapheme cluster iteration
- **UTF Encode Iterators**: Convert between encodings during iteration
- **Output Iterators**: Write encoded data during iteration

## Module-Specific Conventions

### Namespace Organization
- Primary namespace: `NMib::NStr`
- System integration: `NMib::NSys::NStr`
- Private implementations: `NMib::NStr::NPrivate`

### Naming Patterns
- String classes: `C[Encoding]Str[Variant]` (e.g., `CStr`, `CWStrSecure`)
- Template classes: `TC[Component]` (e.g., `TCStr`, `TCFormat`)
- String traits: `CStrTraits_[Type]` (e.g., `CStrTraits_CStr`)
- Algorithms: Direct names (e.g., `Find`, `Replace`, `Trim`)
- Character types: `ch8`, `ch16`, `ch32` (signed), `uch8`, `uch16`, `uch32` (unsigned)

### Character Type System
```cpp
// Signed character types
ch8  - UTF-8/ANSI character
ch16 - UTF-16 character
ch32 - UTF-32/Unicode codepoint

// Unsigned variants
uch8, uch16, uch32

// Zero-on-destruction variants (secure)
zuch8, zuch16, zuch32
```

### String Type Encoding
```cpp
enum EStrType {
    EStrType_Ansi,    // Single-byte ANSI/ASCII
    EStrType_Unicode, // Full Unicode (UTF-32)
    EStrType_UTF,     // Variable-width UTF (8 or 16)
    EStrType_Undefined
};
```

## Dependencies

### Internal Malterlib Modules
- **Core** - Basic types and platform abstractions
- **Container** - Vector for string storage
- **Memory** - Allocator interfaces
- **Algorithm** - Sorting and searching primitives
- **Iterator** - Iterator base classes
- **Encoding** - Character encoding conversions

## Architecture Details

### String Storage Architecture
```cpp
// Strings use template-based storage implementations
template <typename t_CStrTraits>
class TCStr {
    // Storage delegated to implementation class
    typename t_CStrTraits::CImpl m_Impl;
};

// Dynamic implementation example
template <typename t_CStrTraits>
class TCStrImp_Dynamic {
    ch8* m_pData;
    mint m_Capacity;
    mint m_Length;
};
```

### Algorithm Modular Design
Each algorithm is in a separate header for compilation efficiency:
- `Malterlib_String_Algorithm_[Name].h` - Interface
- `Malterlib_String_Algorithm_[Name].hpp` - Implementation

### Format System
```cpp
// Type-safe formatting with compile-time checking
auto Result = "Value: {}, Float: {}"_f << 42 << 3.14f;

// Or using CFormat directly
CStr Result2 = CStr::CFormat("Value: {}, Float: {}") << 42 << 3.14f;
```

### Unicode Support
- Full Unicode support with proper grapheme cluster handling
- Automatic encoding conversion between string types
- Iterator-based encoding transformation
- Normalization and case folding support

## Common Tasks

### Basic String Operations
```cpp
CStr Str("Hello World");
Str.f_Replace("World", "Malterlib");
Str.f_ToUpperCase();

if (Str.f_StartsWith("HELLO")) {
    auto Pos = Str.f_Find("MALTERLIB");
}
```

### String Formatting (Three Variants)

#### 1. CFormat - Object-based formatting
```cpp
// Create formatted string directly
CStr Formatted = CStr::CFormat("Value: {}") << 42;

// Multiple values
CStr UserInfo = CStr::CFormat("User: {}, ID: {}") << Username << UserID;

// With format specifiers
CStr HexFormat = CStr::CFormat("{nh}") << 255;  // Outputs hex without 0x prefix

// Format into existing string by concatenation
CStr Result;
Result += CStr::CFormat("Temperature: {}°C") << Temperature;
```

#### 2. User-defined literal _f - Concise inline formatting
```cpp
// Using the _f suffix for format strings
auto Result = "User: {}, ID: {}"_f << Username << UserID;

// Works with different string types
auto WideResult = u"Value: {}"_f << 42;      // UTF-16
auto UnicodeResult = U"Value: {}"_f << 42;    // UTF-32

// In test paths and debugging
DMibTestPath("{}"_f << TestValue);
```

#### 3. fg_Format - Function-based formatting
```cpp
// Generic format function
CStr Result = fg_Format("Temperature: {}°C", Temperature);

// Format with specific return type
CWStr WideResult = fg_Format<CWStr>("Value: {}", Value);

// Used with format modifiers
auto HexStr = fg_Format("Hex: {}", fg_FormatIntFormat<16>(255));

// Format integer with specific radix
auto Binary = fg_Format("Binary: {}", fg_FormatIntFormat<2>(42));
```

### Parsing
```cpp
// Parse with format string
CStr Input("42 3.14 Hello");
int32 IntVal;
float FloatVal;
CStr StrVal;

aint nParsed = 0;
(CStr::CParse("{} {} {}") >> IntVal >> FloatVal >> StrVal).f_Parse(Input, nParsed);

// Parse with delimiters
CStr String1, String2, String3;
(CStr::CParse("{}...{}...{}") >> String1 >> String2 >> String3).f_Parse("Test1...Test2...Test3", nParsed);

// Parse escaped strings
CStr QuotedStr;
(CStr::CParse("{se}") >> QuotedStr).f_Parse("\"Hello World\"", nParsed);  // {se} = string escaped
```

### Encoding Conversion
```cpp
CStr UTF8String("Hello 世界");
CWStr UTF16String = UTF8String;  // Automatic conversion
CUStr UnicodeString = UTF8String;  // Full Unicode

// Manual conversion
CAnsiStr AnsiStr;
fg_SystemEncodeAnsiStr(UTF8String, AnsiStr, '?'); // '?' for unmappable chars
```

### Using Different Storage
```cpp
// Fixed-size stack string
TCStrFixed<256> StackStr("Stack allocated");

// Secure string (wiped on destruction)
CStrSecure Password("secret");

// String span (non-owning view)
CStrSpan View(SomeString.f_GetArray(), SomeString.f_GetLen());

// Compile-time constant strings
constexpr auto& MyConstStr = gc_Str<"Compile-time constant">.m_Str;  // CStr const
constexpr auto& MyWideStr = gc_Str<str_utf16("Wide string")>.m_Str;  // CWStr const
constexpr auto& MyUnicodeStr = gc_Str<str_utf32("Unicode")>.m_Str;   // CUStr const

// Interoperability with runtime strings
CStr RuntimeStr = gc_Str<"Hello">.m_Str;  // Seamless usage
RuntimeStr += " World";

// Same gc_Str instance across translation units (singleton)
auto& ConstRef1 = gc_Str<"Same">.m_Str;
auto& ConstRef2 = gc_Str<"Same">.m_Str;  // Same address as ConstRef1
```

### Wildcard Matching
```cpp
// Function returns EMatchWildcardResult enum
if (NStr::fg_StrMatchWildcard(Filename, "*.txt") == NStr::EMatchWildcardResult_WholeStringMatchedAndPatternExhausted) {
    // Process text file
}

// Wildcard patterns:
// ? - matches single character
// * - matches zero or more characters
auto Result = NStr::fg_StrMatchWildcard("test.txt", "*.txt");
auto Result2 = NStr::fg_StrMatchWildcard("file123.doc", "file???.doc");
```

### Running Module Tests
```bash
# Build tests
MalterlibBuildShowProgress=false ./mib build Tests macOS arm64 Debug

# Run all string tests
/opt/Deploy/Tests/RunAllTests --paths '["String/*"]'

# Run specific algorithm tests
/opt/Deploy/Tests/RunAllTests --paths '["String/Algorithm/Compare", "String/Algorithm/Find"]'

# Run format/parse tests
/opt/Deploy/Tests/RunAllTests --paths '["String/Container/Format/*", "String/Container/Parse"]'
```

## Important Files

### Headers (Public API)
- `Include/Mib/String/String` - Main string classes
- `Include/Mib/String/Algorithm` - Algorithm interfaces
- `Include/Mib/String/Formatters/*` - Formatting components
- `Include/Mib/String/Parsers/*` - Parsing components
- `Include/Mib/String/Implementations/*` - Storage implementations

### Core Implementation
- `Source/Malterlib_String.h/cpp` - Main string implementation
- `Source/Malterlib_String_Container.h/cpp` - Container base
- `Source/Malterlib_String_Types.h` - Type definitions and traits

### Algorithms
- `Source/Malterlib_String_Algorithm_*.h/hpp` - Individual algorithms
- `Source/Malterlib_String_Algorithm_Common.h` - Shared algorithm code

### Storage Implementations
- `Source/Malterlib_String_Container_Imp*.h` - Storage backends
- Dynamic, Fixed, Virtual, Pointer implementations

### Formatting & Parsing
- `Source/Malterlib_String_Container_Format_*.h` - Formatters
- `Source/Malterlib_String_Container_Parse_*.h` - Parsers
- `Source/Malterlib_String_FormatUtils.h/hpp` - Format utilities

### Unicode & Encoding
- `Source/Malterlib_String_Iterator_Unicode.h/hpp` - Unicode iteration
- `Source/Malterlib_String_Iterator_UTF*.h/hpp` - UTF encoding iterators
- `Source/Malterlib_String_UnicodeConversion.h` - Conversion utilities
- `Source/Malterlib_String_AnsiConversion.h` - ANSI conversion

### Special Features
- `Source/Malterlib_String_FuzzyMatch.h/cpp` - Fuzzy string matching
- `Source/Malterlib_String_MultiReplace.h/hpp` - Batch replacements
- `Source/Malterlib_String_Appender.h/hpp` - Efficient string building

## Module-Specific Notes

### Performance Characteristics
- **Small String Optimization** (SSO) in dynamic implementation
- **Copy-on-Write** (COW) for efficient string copies
- **Algorithm complexity**:
  - Find/Replace: O(n*m) worst case, optimized for common cases
  - Hash functions: O(n) with good distribution
  - Case conversion: O(n) with Unicode support
  - Wildcard match: O(n*m) with optimization for simple patterns

### Character Encoding
- UTF-8 is default and recommended for most use cases
- UTF-16 for Windows API compatibility
- UTF-32 when direct codepoint access needed
- ANSI for legacy system compatibility
- Automatic conversion between types with potential data loss warnings

### Memory Management
- Dynamic strings use exponential growth (typically 1.5x)
- NonTracked variants bypass memory tracking system
- Secure variants clear memory on destruction
- Fixed variants never allocate heap memory

### Thread Safety
- String objects are NOT thread-safe for modification
- Read-only access from multiple threads is safe
- Use synchronization for concurrent modifications
- Consider thread-local strings for performance

### Unicode Considerations
- Full Unicode 15.0 support
- Proper handling of:
  - Combining characters
  - Surrogate pairs (UTF-16)
  - Grapheme clusters
  - Normalization forms
- Case operations are Unicode-aware

### Format System Features
- Type-safe compile-time checking
- Custom format specifiers:
  - `{}` - Default formatting
  - `{nh}` - Hex without prefix (no 0x)
  - Custom radix via `fg_FormatIntFormat<radix>`
- Three formatting approaches:
  - `CFormat` - Object-oriented, best for building complex strings
  - `_f` literal - Concise, best for inline formatting
  - `fg_Format` - Functional, best for simple format operations
- Automatic type deduction
- Efficient buffer management
- Supports all basic types and custom types with format traits

### Known Limitations
- Wildcard matching doesn't support full regex (use separate Regex module)
- ANSI conversion may lose data for Unicode strings
- Fixed strings have compile-time size limits
- Some algorithms not optimized for very long strings (>1MB)

### Best Practices
- Use `CStr` (UTF-8) as default string type
- Use `CStrSpan` for function parameters to avoid copies
- Prefer algorithms over manual iteration
- Use secure strings for sensitive data (passwords, keys)
- Reserve capacity when final size is known
- Use MultiReplace for batch replacements (more efficient)
- Consider Fixed strings for stack allocation in performance-critical code

### Common String Formatting Mistakes

**Compilation Error with `_f` Operator**

The `_f` string formatting operator requires the `NMib::NStr` namespace to be in scope:

```cpp
// INCORRECT - will cause compilation error
auto Result = "Value: {}"_f << 42;

// CORRECT - add using declaration before formatting
using namespace NMib::NStr;
auto Result = "Value: {}"_f << 42;
```

**Solution**: Add `using namespace NMib::NStr;` locally before using the `_f` formatting operator at the top of the function. If you are in a cpp file you can put the using declaration at the top of the file.

<!-- End include: Malterlib/String/CLAUDE.md -->
<!-- Begin include: Malterlib/Storage/CLAUDE.md -->
# CLAUDE.md - Storage Module

This file provides guidance to Claude Code (claude.ai/code) when working with the Storage module in Malterlib.

## Module Overview

The Storage module provides advanced memory management and data storage utilities for C++ applications. It implements custom smart pointers, optional types, variants, lazy initialization patterns, and other storage-related abstractions that integrate with Malterlib's memory management system.

## Architecture

### Namespace Organization
- **NMib::NStorage** - Main storage namespace containing all primary storage utilities
- **NMib::NStorage::NReference** - Reference wrapper implementation
- **NMib::NStorage::NPrivate** - Internal implementation details

### Component Categories

#### Smart Pointers
- **TCSharedPointer** - Reference-counted smart pointer with thread-safe operations
- **TCUniquePointer** - Single-ownership smart pointer with custom allocator support
- **TCWeakPointer** - Non-owning weak reference to shared pointer objects
- **TCBitStorePointer** - Pointer that stores extra bits in unused address bits (for alignment-guaranteed allocations)
- **CAutoClearPtr** - Auto-clearing pointer for debugging reference counting issues

#### Container Types
- **TCOptional** - Optional value container (similar to std::optional)
- **TCVariant** - Type-safe discriminated union (similar to std::variant)
- **TCTuple** - Tuple implementation (wraps std::tuple with Malterlib integration)
- **TCAggregate** - Aggregate data storage with prioritized destruction

#### Memory Management
- **TCLazyInit** - Thread-safe lazy initialization pattern
- **TCIndirection** - Indirection layer for pointer-like semantics
- **TCReference** - Reference wrapper with additional safety features

### File Organization

```
Storage/
├── Include/Mib/Storage/    # Public headers for each component
│   ├── Aggregate
│   ├── AutoClearPointer
│   ├── BitStorePointer
│   ├── DebugPointer
│   ├── Indirection
│   ├── LazyInit
│   ├── Optional
│   ├── Pointer
│   ├── Reference
│   ├── SharedPointer
│   ├── Tuple
│   ├── UniquePointer
│   └── Variant
├── Source/                 # Implementation files
│   ├── Malterlib_Storage_*.h     # Main headers
│   ├── Malterlib_Storage_*.hpp   # Template implementations
│   ├── Malterlib_Storage_*.cpp   # Non-template implementations
│   └── Private/            # Internal helpers
│       ├── *_Helpers.h
│       └── *_Traits.h
└── Test/                   # Unit tests
    └── Test_Malterlib_Storage_*.cpp
```

## Key Components

### Smart Pointers

#### TCSharedPointer
- Thread-safe reference counting
- Custom allocator support
- Weak pointer support
- Debug modes for leak detection (DMibConfig_RefCountDebugging, DMibConfig_RefCountLeakDebugging)

#### TCUniquePointer
- Single ownership semantics
- Custom allocator support via template options
- Move-only semantics
- Supports polymorphic types with virtual destructors

#### TCBitStorePointer
- Stores extra bits in unused pointer bits (template parameter t_nBits)
- Default 2 bits for 32-bit system safety
- Useful for tagged pointers and compact data structures

### Container Types

#### TCOptional<t_CType>
- Inherits from TCStreamableVariant for serialization support
- Construct-in-place support via TCConstruct helper
- Conversion operators for seamless usage
- Has-value checking and value access methods

#### TCVariant<tp_CTypes...>
- Type-safe discriminated union
- Visitor pattern support
- Automatic destruction of active member
- Index-based and type-based access

#### TCLazyInit<t_CData, t_CLock>
- Thread-safe lazy initialization
- Configurable lock type (defaults to CLowLevelLockAggregate)
- Lifetime tracking flags (Constructed/Destructed)
- Construct-on-first-use pattern

### Memory Utilities

#### TCAggregate<t_CData, t_Priority, t_CLock>
- Prioritized destruction order
- Thread-safe lifetime management
- Module registration for cleanup
- Debug support for tracking lifetime issues

## Usage Patterns

### Smart Pointer Usage
```cpp
// Shared pointer construction
TCSharedPointer<CMyClass> pShared = fg_Construct(args...);

// Shared pointer with derived class
TCSharedPointer<CBase> pBase = fg_Construct<CDerived>(args...);

// Shared pointer with custom allocator
TCSharedPointer<CMyClass, CCustomAllocator> pSharedCustom = fg_Construct(args...);

// Unique pointer construction
TCUniquePointer<CMyClass> pUnique = fg_Construct(args...);

// Unique pointer with derived class
TCUniquePointer<CBase> pBaseUnique = fg_Construct<CDerived>(args...);

// Weak pointer from shared
TCWeakPointer<CMyClass> pWeak = pShared;
```

### Optional Usage
```cpp
TCOptional<int> OptValue;
OptValue = 42;
if (OptValue)
    int Value = *OptValue;
```

### Lazy Initialization
```cpp
TCLazyInit<CExpensiveObject> LazyObject;
// Object constructed on first access
CExpensiveObject &Object = *LazyObject;
```

### Variant Usage
```cpp
TCVariant<int, float, CString> Value;
Value = 42;
// Visit pattern for type-safe access
Value.f_Visit([](auto &_Value) { /* process _Value */ });
```

## Configuration Macros

### Debug Configuration

#### Compile-time Debug Macros
- **DMibConfig_RefCountDebugging** - Enable reference counting debug output (default: 0)
- **DMibConfig_RefCountLeakDebugging** - Enable leak detection for shared pointers (default: 0)
- **DIfRefCountDebugging(...)** - Conditional compilation for debug code
- **DIfNotRefCountDebugging(...)** - Inverse conditional compilation

#### Runtime Debug Settings
To enable reference counting debugging for tracking memory leaks and reference issues, uncomment these lines in `BuildSystem/Default/UserSettings.MSettings`:

```makefile
Property // Debug
{
    Malterlib_RefCountDebugging_Enable true // Set to true to enable shared pointer reference debugging
    Malterlib_RefCountLeakDebugging_Enable true // Set to true to enable tracing information about shared pointer references when displaying memory leaks
}
```

After modifying UserSettings.MSettings, regenerate and rebuild your workspace for changes to take effect.

### Variant Configuration
- **DMibStorageVariantTypeInMember(...)** - MSVC workaround for variant member types

## Testing

The module includes comprehensive unit tests in the Test/ directory:
- **Test_Malterlib_Storage_Pointer.cpp** - Smart pointer tests
- **Test_Malterlib_Storage_Indirection.cpp** - Indirection layer tests
- **Test_Malterlib_Storage_Tuple.cpp** - Tuple functionality tests
- **Test_Malterlib_Storage_Variant.cpp** - Variant tests
- **Test_Malterlib_Storage_WeakPointer.cpp** - Weak pointer specific tests

Tests use the NMib::NTest framework and cover:
- Construction/destruction patterns
- Thread safety
- Memory leak detection
- Edge cases and error conditions

## Integration with Other Modules

### Dependencies
- **Core** - Base types and macros
- **Memory** - Allocator interfaces and memory management
- **Atomic** - Atomic operations for thread-safe reference counting
- **Thread** - Lock types for synchronization
- **Meta** - Template metaprogramming utilities
- **Function** - Function binding for callbacks
- **Stream** - Serialization support for variants and optionals
- **Contract** - Debug assertions and contract checking

### Used By
- Most Malterlib modules use Storage for smart pointer management
- Container module uses Storage types for internal implementation
- Concurrency module relies on thread-safe storage patterns

## Important Notes

1. **Thread Safety**: Most storage types are thread-safe for const operations only. TCSharedPointer provides full thread safety for reference counting.

2. **Allocator Support**: Smart pointers support custom allocators that must derive from NMemory::CAllocator_Base.

3. **Debug Builds**: Enable ref count debugging macros in debug builds to catch memory leaks and lifetime issues early.

4. **Performance**: TCBitStorePointer and lazy initialization patterns are optimized for performance-critical code.

5. **Exception Safety**: All storage types provide basic exception safety guarantees, with strong guarantees for smart pointer operations.

6. **Lifetime Management**: CAutoClearPtr and aggregate patterns help manage complex object lifetimes in multi-threaded environments.

7. **Type Safety**: Variant and optional types provide compile-time type safety with runtime checking in debug builds.

8. **Memory Alignment**: TCBitStorePointer assumes proper alignment for storing bits in pointer values.

## Common Pitfalls

1. Don't mix allocators when transferring ownership between smart pointers
2. Ensure proper locking when using TCLazyInit in multi-threaded contexts
3. Be careful with TCBitStorePointer on platforms with different alignment requirements
4. Don't store references in TCOptional or TCVariant - use pointers or TCReference
5. Avoid circular references with TCSharedPointer - use TCWeakPointer to break cycles

## Best Practices

1. Prefer TCUniquePointer for single ownership scenarios
2. Use TCSharedPointer only when shared ownership is truly needed
3. Enable debug configurations during development to catch issues early
4. Use TCOptional instead of nullable pointers when null is a valid state
5. Leverage TCVariant for type-safe unions instead of void* or type erasure
6. Use TCLazyInit for expensive objects that may not be used
7. Prefer TCReference over raw references when lifetime tracking is needed

<!-- End include: Malterlib/Storage/CLAUDE.md -->
<!-- Begin include: Malterlib/Container/CLAUDE.md -->
# CLAUDE.md - Container Module

## Module Overview

The Container module provides high-performance, STL-compatible container classes built on top of the Intrusive module's primitives. These containers offer both intrusive and non-intrusive options with superior performance characteristics compared to standard implementations, while maintaining familiar interfaces for ease of use.

## Key Components

### Core Containers
- **Vector** (`TCVector`) - Dynamic array with configurable growth/shrink policies
  - Options for minimum size, shrinking behavior, bounds checking
  - Extensive operation support through modular implementation files
  - Iterator support with bidirectional and reverse variants

- **Map** (`TCMap`) - Ordered associative container based on AVL tree
  - Built on intrusive AVL tree for O(log n) operations
  - Multiple iterator types: value, key, key-value access
  - Node handles for efficient extraction/insertion
  - Batch operations support

- **Set** (`TCSet`) - Ordered unique element container
  - Shares implementation with Map (value-only)
  - Format and comparison support

- **LinkedList** - Non-intrusive wrapper around intrusive lists
  - Provides STL-like interface
  - Automatic memory management

### Specialized Containers
- **MapWithPool** / **SetWithPool** - Pool-allocated variants for performance
- **PagedByteVector** - Efficiently handles large byte arrays with paging
- **BitArray** - Compact bit storage with multiple implementations:
  - Standard BitArray
  - BitArrayHierarchical - Multi-level bit indexing
  - BitArrayPowerTwo - Optimized for power-of-2 sizes

- **Registry** - Hierarchical key-value store (like Windows Registry)
  - Mixed type support
  - String table optimization
  - Path-based access
  - Diff/merge capabilities

- **Regions** - Memory region management container

## Module-Specific Conventions

### Namespace Organization
- Primary namespace: `NMib::NContainer`
- Private implementations: `NMib::NContainer::NPrivate`

### Naming Patterns
- Template containers: `TC[Container]` (e.g., `TCVector`, `TCMap`)
- Options structures: `TC[Container]Options` (e.g., `TCVectorOptions`)
- Node types: `TC[Container]Node` (e.g., `TCMapNode`)
- Iterators: `C[Container]Iterator[Variant]` (e.g., `CMapIteratorBidirectional`)
- Results: `TC[Container]Result` (e.g., `TCMapResult`)

### Template Parameters Convention
- `t_CData` / `t_CKey` / `t_CValue` - Element types
- `t_CCompare` - Comparison functor (defaults to `CSort_Default`)
- `t_CAllocator` - Memory allocator (defaults to `CAllocator_Heap`)
- `t_COptions` - Container-specific options

### Function Naming
- `f_*` - Regular member functions
- `f_Get*` - Accessor functions
- `f_Insert*` - Insertion operations
- `f_Remove*` - Removal operations
- `f_Find*` - Search operations

## Dependencies

### Internal Malterlib Modules
- **Intrusive** - Provides underlying AVL tree and linked list implementations
- **Core** - Basic types and platform abstractions
- **Memory** - Allocator interfaces
- **Algorithm** - Sorting and searching algorithms
- **Iterator** - Iterator base classes
- **Stream** - Serialization support
- **String** - String operations for Registry

## Architecture Details

### Vector Implementation
```cpp
// Configurable vector options
template <mint t_MinSize, bool t_bShrink, bool t_bCheckBounds>
struct TCVectorOptions {
    static constexpr mint mc_MinSize = t_MinSize;        // Minimum allocation
    static constexpr bool mc_bShrink = t_bShrink;        // Auto-shrink on remove
    static constexpr bool mc_bCheckBounds = t_bCheckBounds; // Bounds checking
};
```

### Map Architecture
```cpp
// Built on intrusive AVL tree - nodes contain both key and value
template <typename t_CKey, typename t_CValue>
struct TCMapNode {
    NIntrusive::CAVLLink m_Link;  // Intrusive link
    t_CKey m_Key;
    t_CValue m_Value;
};
```

### Registry Structure
```cpp
// Hierarchical storage with mixed types
// Supports: bool, int, float, string, binary data
// Path-based access: "Software/Company/Product/Setting"
```

### Modular Implementation
The Container module uses extensive header separation for maintainability:
- Core headers define interfaces
- Implementation split into operation-specific files
- Example for Vector:
  - `Vector_Insert*.hpp` - Various insertion methods
  - `Vector_Remove.hpp` - Removal operations
  - `Vector_Sort.hpp` - Sorting functionality
  - `Vector_Stream.hpp` - Serialization

## Common Tasks

### Using Vector with Custom Options
```cpp
// Define custom options
using CMyOptions = TCVectorOptions<32, false, true>; // Min 32, no shrink, bounds check
using CMyVector = TCVector<int, CAllocator_Heap, CMyOptions>;

CMyVector Vec;
Vec.f_InsertLast(42);
```

### Map with Custom Comparison
```cpp
struct CMyCompare {
    auto operator()(CMyKey const &_Left, CMyKey const &_Right) const {
        return _Left.m_Priority <=> _Right.m_Priority;  // Three-way comparison
    }
};
using CMyMap = TCMap<CMyKey, CMyValue, CMyCompare>;
```

### Registry Usage
```cpp
CRegistry Reg;
Reg.f_SetValue("Software/MyApp/Version", "1.0.0");
auto Version = Reg.f_GetString("Software/MyApp/Version");
```

### Running Module Tests
```bash
# Build tests
MalterlibBuildShowProgress=false ./mib build Tests macOS arm64 Debug

# Run all container tests
/opt/Deploy/Tests/RunAllTests --paths '["Container/*"]'

# Run specific tests
/opt/Deploy/Tests/RunAllTests --paths '["Container/Vector", "Container/Map"]'

# Performance tests
/opt/Deploy/Tests/RunAllTests --paths '["Container/MapPerformance", "Container/VectorPerformance"]'
```

## Important Files

### Headers (Public API)
- `Include/Mib/Container/*` - Public interfaces for all containers

### Core Container Implementations
- `Source/Malterlib_Container_Vector.h/cpp` - Vector implementation
- `Source/Malterlib_Container_Map.h` - Map implementation
- `Source/Malterlib_Container_Set.h` - Set implementation
- `Source/Malterlib_Container_LinkedList.h` - Linked list wrapper
- `Source/Malterlib_Container_Registry.h/cpp` - Registry implementation

### Specialized Containers
- `Source/Malterlib_Container_BitArray*.h` - Bit array variants
- `Source/Malterlib_Container_PagedByteVector.h/cpp` - Paged byte storage
- `Source/Malterlib_Container_Regions.h` - Region management
- `Source/Malterlib_Container_*WithPool.h` - Pool-allocated variants

### Modular Implementation Directories
- `Source/Vector/*.hpp` - Vector operation implementations
- `Source/Map/*.hpp` - Map operation implementations
- `Source/Set/*.hpp` - Set operation implementations
- `Source/Registry/*.hpp` - Registry operation implementations

## Module-Specific Notes

### Performance Characteristics
- **Vector**: O(1) append/remove at end, O(n) insert/remove in middle
- **Map/Set**: O(log n) all operations (AVL tree balanced)
- **Pool variants**: For special cases, for example when memory manager is not yet available. Usually memory manager is more efficient
- **BitArray**: O(1) bit operations, hierarchical variants offer fast scanning
- **Registry**: O(log n) per path component

### Comparison with STL
- Generally faster than STL due to:
  - Intrusive foundations (fewer allocations)
  - Better cache locality
  - Optimized allocators
  - Three-way comparison operator usage
- See `Documentation/Malterlib_Container_STLComparison.dox` for details

### Memory Management
- Containers manage memory for non-intrusive elements
- Vector shrinking is configurable per instance
- Registry uses string table for key deduplication

### Thread Safety
- Containers are NOT thread-safe by default
- External synchronization required
- Consider using concurrent variants from Concurrency module
- Read-only access from multiple threads is safe

### Iterator Invalidation Rules
- **Vector**: Invalidated on reallocation (insert/remove)
- **Map/Set**: All iterators are invalidated on insert/remove
- **LinkedList**: Only iterators to removed elements invalidated
- **Registry**: Path-based access remains valid across modifications
- Bidirectional iterators support both forward and backward traversal
- For Map/set bidirectional are less efficient so use forward/backward iterator only if sufficient

### Design Patterns
- Heavy use of templates for compile-time optimization
- Modular implementation through included headers
- Options structures for configurable behavior
- Node handles for efficient element transfer between containers

### Known Limitations
- Registry paths limited to reasonable depth (implementation defined)
- BitArrayHierarchical has overhead for small bit counts
- Vector bounds checking has runtime cost (configurable)

### Best Practices
- Use pool variants when container size is predictable
- Configure vector options based on usage patterns
- Prefer iterators over index access for traversal
- Use Registry for hierarchical configuration data
- Consider BitArrayPowerTwo for power-of-2 sized bit sets

<!-- End include: Malterlib/Container/CLAUDE.md -->
<!-- Begin include: Malterlib/Encoding/CLAUDE.md -->
# CLAUDE.md - Encoding Module

This file provides guidance to Claude Code (claude.ai/code) when working with the Encoding module in Malterlib.

## Module Overview

The Encoding module provides comprehensive text encoding and data serialization functionality, focusing heavily on JSON processing with additional support for Base64, Bin128, and enhanced JSON formats. The module is designed for high performance with multiple JSON implementations for different use cases.

## Module Location

- **Main Directory**: `Malterlib/Encoding/`
- **Include Path**: `Include/Mib/Encoding/`
- **Source Files**: `Source/Malterlib_Encoding_*.cpp/.h/.hpp`
- **Tests**: `Test/Test_Malterlib_Encoding_*.cpp`

## Core Components

### 1. Base64 Encoding (`Base64`)
Provides Base64 encoding/decoding functionality for strings and binary data.

**Key Classes/Functions**:
- `TCBinaryStream_Base64` - Stream-based Base64 encoding/decoding
- `fg_Base64Encode()` - Encode strings or byte vectors to Base64
- `fg_Base64Decode()` - Decode Base64 strings to original format

**Usage Example**:
```cpp
NStr::CStr EncodedText = fg_Base64Encode("Hello World");
NStr::CStr DecodedText = fg_Base64Decode(EncodedText);

// Binary data encoding
NContainer::CByteVector BinaryData;
NStr::CStr EncodedBinary = fg_Base64Encode(BinaryData);
```

### 2. Bin128 Encoding (`Bin128`)
Handles 128-bit binary value encoding and manipulation.

**Key Classes**:
- Binary 128-bit value handling and string conversion

### 3. JSON Processing (`Json`)
Comprehensive JSON support with two main variants: Ordered and Sorted.

**Main Classes**:
- `CJsonOrdered` - Preserves insertion order of object keys
- `CJsonSorted` - Automatically sorts object keys lexicographically
- `TCJsonValue` - Template base for JSON values
- `TCJsonObject` - JSON object representation

**JSON Types** (`EJsonType`):
- `EJsonType_Invalid` - Invalid/uninitialized value
- `EJsonType_Null` - null value
- `EJsonType_String` - String value
- `EJsonType_Integer` - Integer value (int64)
- `EJsonType_Float` - Floating point value (fp64)
- `EJsonType_Boolean` - Boolean value
- `EJsonType_Object` - Object/dictionary
- `EJsonType_Array` - Array/list

**Common Operations**:
```cpp
// Creating JSON objects
CJsonOrdered Json(EJsonType_Object);
Json["Key"] = "Value";
Json["Number"] = 42;
Json["Float"] = 3.14;
Json["Boolean"] = true;
Json["Null"] = nullptr;

// Arrays
auto &Array = Json["Array"];
Array.f_Insert(25);
Array.f_Insert("Text");
Array.f_Insert(true);

// Nested objects
auto &NestedObject = Json["Object"];
NestedObject["NestedKey"] = "NestedValue";

// Parsing from string
CJsonOrdered ParsedJson = CJsonOrdered::fs_FromString(JsonString);

// Converting to string
NStr::CStr JsonString = fg_JsonGenerate(Json);
```

### 4. Enhanced JSON (`EJson`)
Extended JSON format supporting additional data types beyond standard JSON.

**Additional Types** (`EEJsonType`):
- All standard JSON types plus:
- `EEJsonType_Date` - Date/time values
- `EEJsonType_Binary` - Binary data
- `EEJsonType_UserType` - Custom user-defined types

**Key Classes**:
- `CEJsonOrdered` - Enhanced JSON with ordered keys
- `CEJsonSorted` - Enhanced JSON with sorted keys
- `CEJsonUserTypeOrdered/Sorted` - User-defined type containers

**Usage Example**:
```cpp
CEJsonOrdered EJson;
EJson["Date"] = NTime::CTime::fs_Now();
EJson["Binary"] = NContainer::CByteVector{0x01, 0x02, 0x03};
EJson["Custom"] = fg_UserTypeOrdered("MyType", CJsonOrdered{{"data", "value"}});
```

### 5. JSON Shortcuts (`JsonShortcuts`)
Provides convenient literal operators for JSON construction.

**Operators**:
- `"key"_j` - Creates a JSON key
- `_j[]` - Creates an empty JSON array
- `_j= {}` - Creates a JSON object
- `"key"_` - Creates a EJSON key
- `_[]` - Creates an empty EJSON array
- `_= {}` - Creates a EJSON object

**Usage Example**:
```cpp
CJsonSorted Json =
{
	"Name"_j= "John"
	, "Age"_j= 30
	, "Address"_j=
	{
		"Street"_j= "123 Main St"
		, "City"_j= "New York"
	}
	, "Hobbies"_j= _j["Reading", "Gaming", "Coding"]
};

CEJsonSorted EJson =
{
	"Name"_= "John"
	, "Age"_= 30
	, "Address"_=
	{
		"Street"_= "123 Main St"
		, "City"_= "New York"
	}
	, "Hobbies"_= _["Reading", "Gaming", "Coding"]
};
```

### 6. Simple JSON Database (`SimpleJsonDatabase`)
Provides a simple file-based JSON database with async load/save operations.

**Key Features**:
- Async file operations using futures
- Thread-safe write operations with sequencer
- Automatic JSON serialization/deserialization

**Usage Example**:
```cpp
CSimpleJsonDatabase Database("data.json");
co_await Database.f_Load();
// Modify Database.m_Data
co_await Database.f_Save();
```

### 7. ToJson Conversion (`ToJson`)
Utilities for converting various types to JSON representation.

## External Dependencies

The module integrates with several external JSON libraries for comparison and testing:
- **rapidjson** - Tencent's RapidJSON library
- **nlohmann/json** - Popular modern C++ JSON library
- **daw_json_link** - High-performance JSON library
- **header_libraries** - Supporting header libraries
- **utf_range** - UTF string range utilities

These are only included when `MalterlibEnableThirdPartyComparisonTests` is enabled.

## Code Patterns and Conventions

### Naming Conventions
Following Malterlib standards:
- Functions: `f_` prefix for members, `fg_` for global functions
- Member variables: `m_` prefix
- Private/protected members: `mp_` prefix
- Template parameters: `t_` prefix
- Constants: `mc_` prefix for member constants, `gc_` for global

### JSON Value Access Patterns
```cpp
// Type checking
if (Json.f_IsObject())
{
	// Safe member access
	if (CJsonOrdered const *pValue = Json.f_GetMember("Key"))
	{
		// Use pValue
	}

	// Direct access (creates if missing)
	Json["Key"] = "Value";

	// Get with default
	int64 Value = Json.f_GetMemberValue("Count", 0).f_Integer();
}

// Array operations
if (Json.f_IsArray())
{
	for (auto const &Element : Json.f_Array())
	{
		// Process element
	}
}
```

### Type Conversion
```cpp
// Safe type conversion with defaults
NStr::CStr StringValue = Json.f_AsString("default");
int64 IntValue = Json.f_AsInteger(0);
fp64 FloatValue = Json.f_AsFloat(0.0);
bool BoolValue = Json.f_AsBoolean(false);

// Direct type access (throws on wrong type)
NStr::CStr &String = Json.f_String();
int64 &Integer = Json.f_Integer();
fp64 &Float = Json.f_Float();
bool &Boolean = Json.f_Boolean();
```

## Performance Characteristics

### JSON Variants
- **CJsonOrdered**: Preserves insertion order, best for APIs and user-facing data
- **CJsonSorted**: Auto-sorts keys, best for comparison and hashing, uses less memory and is faster

### Stream Support
The module supports efficient streaming for large JSON documents:
```cpp
// Binary stream serialization
NContainer::CByteVector ByteVector = NStream::fg_ToByteVector(Json);
CJsonOrdered Restored = NStream::fg_FromByteVector<CJsonOrdered>(ByteVector);
```

## Testing

The module includes comprehensive tests in the `Test/` directory:
- `Test_Malterlib_Encoding_Base64.cpp` - Base64 encoding tests
- `Test_Malterlib_Encoding_Bin128.cpp` - Bin128 tests
- `Test_Malterlib_Encoding_Json.cpp` - Core JSON functionality tests
- `Test_Malterlib_Encoding_EJson.cpp` - Enhanced JSON tests
- `Test_Malterlib_Encoding_JsonPerformance.cpp` - Performance benchmarks
- `Test_Malterlib_Encoding_JsonShared.h` - Shared test utilities

Run tests with:
```bash
MalterlibBuildShowProgress=false ./mib build Tests macOS arm64 Debug
/opt/Deploy/Tests/RunAllTests --paths '["Malterlib/Encoding*"]'
```

## Common Use Cases

### 1. Configuration Files
```cpp
CSimpleJsonDatabase Config("app_config.json");
co_await Config.f_Load();
Config.m_Data["Settings"]["Theme"] = "dark";
co_await Config.f_Save();
```

### 2. API Response Handling
```cpp
{
	auto CaptureScope = co_await (g_CaptureExceptions % "Error parsing API response");

	CJsonOrdered Response = CJsonOrdered::fs_FromString(ApiResponseString);
}

if (Response["status"].f_AsString() == "success")
{
	auto const &Data = Response["data"];
	// Process data
}
```

### 3. Data Serialization
```cpp
struct CUserData
{
	NStr::CStr m_Name;
	int32 m_Age;

	CJsonOrdered f_ToJson() const
	{
		return
			{
				"Name"_j= m_Name
				, "Age"_j= m_Age
			}
		;
	}

	void f_FromJson(CJsonOrdered const &_Json)
	{
		m_Name = _Json["Name"].f_AsString();
		m_Age = (int32)_Json["Age"].f_AsInteger();
	}
};
```

### 4. Pretty Printing
```cpp
// Generate formatted JSON with indentation
NStr::CStr PrettyJson = Json.f_ToString();

// Generate colored JSON for terminal output
NStr::CStr ColoredJson = Json.f_ToStringColored(EAnsiEncodingFlag_AllFeatures);
```

## Important Notes

- The module uses custom memory management with Malterlib allocators
- All string operations use `NStr::CStr` instead of `std::string`
- JSON parsing supports various dialects through `EJsonDialectFlag`
- Binary streams support Base64 encoding transparently
- Thread safety is not guaranteed for individual JSON objects - use appropriate locking or `CSimpleJsonDatabase` for concurrent access
- Performance comparison tests against external libraries are available when enabled

## Error Handling

JSON operations may throw exceptions on:
- Parse errors (invalid JSON syntax)
- Type mismatches (accessing wrong type without checking)
- Invalid operations (accessing members on non-objects)

Always validate JSON structure before accessing:
```cpp
try
{
	CJsonOrdered Json = CJsonOrdered::fs_FromString(InputString);
	// Process JSON
}
catch (NException::CException const &_Exception)
{
	// Handle parse error
	DMibLog(Error, "JSON parse error: {}", _Exception);
}
```

<!-- End include: Malterlib/Encoding/CLAUDE.md -->
<!-- Begin include: Malterlib/Concurrency/CLAUDE.md -->
# CLAUDE.md - Concurrency Module

This file provides guidance to Claude Code (claude.ai/code) when working with the Concurrency module in the Malterlib framework.

## Module Overview

The Concurrency module provides a comprehensive actor-based concurrency framework with async/await support, distributed computing capabilities, and safe concurrent programming patterns. Key features include:

- **Actor Model** - Sequential execution within actors, safe concurrent execution across actors
- **Coroutines** - C++20 coroutines with `TCFuture`/`TCPromise` for async/await patterns
- **Distributed Actors** - Transparent remote actor communication across processes and hosts
- **Distributed Applications** - Framework for building distributed systems with authentication and trust management
- **Thread Management** - Run loops, thread pools, and work queues
- **Async Utilities** - AsyncResult, AsyncGenerator, futures, and promises
- **Safe Destruction** - Automatic cleanup and lifetime management

## Architecture

### Core Components

#### Actor System
- **CActor** - Base class for all actors
- **TCActor** - Template wrapper providing type-safe actor references
- **CActorHolder** - Internal management of actor lifetime and execution
- **CConcurrencyManager** - Central coordinator for actor execution and thread pools
- **CRunLoop** - Event loop for actor message processing
- **CRunQueue** - Queue for pending actor messages

#### Async/Await System
- **TCFuture** - Awaitable future type for async operations
- **TCPromise** - Promise type for setting async results
- **TCAsyncResult** - Result type containing value or exception
- **Coroutines** - C++20 coroutine support with safety checks
- **TCAsyncGenerator** - Async generator for streaming results

#### Distributed System
- **TCDistributedActor** - Remote actor reference
- **CDistributedActorManager** - Manages remote actor connections
- **CDistributedApp** - Base class for distributed applications
- **CDistributedTrustManager** - Authentication and trust for distributed actors
- **CRuntimeTypeRegistry** - Runtime type information for remote calls

### Design Principles

1. **Safe Concurrency** - Actors execute sequentially, preventing data races
2. **Always Get Result** - RAII ensures all async operations return a result or exception
3. **Safe Destruction** - Automatic cleanup when actors go out of scope
4. **Minimize Boilerplate** - Operator overloading and coroutines reduce code complexity
5. **Transparent Distribution** - Same API for local and remote actor calls
6. **Linear Scaling** - Lock-free operations and thread pool per core
7. **Low Overhead** - 100-300 cycles per actor call with saturated queue

## File Organization

```
Concurrency/
├── Include/Mib/Concurrency/       # Public headers
│   ├── Actor/                     # Actor-specific utilities
│   ├── *Actor*                    # Actor system headers
│   ├── Async*                     # Async utilities
│   ├── Coroutine                  # Coroutine support
│   ├── Distributed*               # Distributed computing
│   ├── RunLoop/RunQueue           # Execution infrastructure
│   └── ConcurrencyManager         # Central manager
├── Source/                        # Implementation files
│   ├── Actor/                     # Actor implementation
│   ├── DistributedActor/          # Distributed actor implementation
│   ├── DistributedApp/            # Distributed app framework
│   ├── DistributedTrust/          # Trust management
│   └── DistributedDDPBridge/      # DDP bridge implementation
├── Test/                          # Unit tests
├── Apps/                          # Example applications
└── Documentation/                 # Design documentation
```

## Usage Examples

### Basic Actor

```cpp
#include <Mib/Concurrency/ConcurrencyManager>

// Define an actor class
class CMyActor : public CActor
{
public:
	// Async function returning future
	TCFuture<int32> f_Calculate(int32 _Value)
	{
		// Perform async work
		co_await f_DoAsyncWork();

		// Access member data safely (single-threaded within actor)
		m_Counter += _Value;

		co_return m_Counter;
	}

	TCFuture<void> f_DoAsyncWork()
	{
		// Simulate async operation
		co_await fg_Timeout(0.1);
		co_return {};
	}

private:
	int32 m_Counter = 0;
};

// Using the actor
TCFuture<void> f_UseActor()
{
	// Create actor instance
	TCActor<CMyActor> MyActor = fg_Construct<CMyActor>();

	// Call actor method (returns future)
	int32 Result = co_await MyActor(&CMyActor::f_Calculate, 5);

	DConOut("Result: {}\n", Result);

	co_return {};
}
```

### Actor with Callbacks

```cpp
class CEventActor : public CActor
{
public:
	// Register callback with subscription for lifetime management
	TCFuture<CActorSubscription> f_Subscribe(TCActorFunctor<void(int32)> _fCallback)
	{
		auto *pCallback = &m_Callbacks.f_Insert(fg_Move(_fCallback));

		// Return subscription to track lifetime
		co_return g_ActorSubscription / [this, pCallback]
			{
				m_Callbacks.f_Remove(pCallback);
			}
		;
	}

	TCFuture<void> f_TriggerEvent(int32 _Value)
	{
		for (auto &fCallback : m_Callbacks)
		{
			co_await fCallback(_Value);
		}
		co_return {};
	}

private:
	TCLinkedList<TCActorFunctor<void(int32)>> m_Callbacks;
};

// Using subscriptions
TCFuture<void> f_UseSubscription()
{
	TCActor<CEventActor> EventActor = fg_Construct<CEventActor>();

	// Subscribe with automatic cleanup
	CActorSubscription Subscription = co_await EventActor
		(
			&CEventActor::f_Subscribe
			, g_ActorFunctor / [](int32 _Value) -> TCFuture<void>
			{
				DConOut("Event: {}\n", _Value);
				co_return {};
			}
		)
	;

	// Trigger events
	co_await EventActor(&CEventActor::f_TriggerEvent, 42);

	// Subscription automatically cleaned up when it goes out of scope
	co_return {};
}
```

### Error Handling

```cpp
class CErrorActor : public CActor
{
public:
	TCFuture<int32> f_MayFail(bool _bShouldFail)
	{
		if (_bShouldFail)
			co_return DMibErrorInstance("Operation failed");

		co_return 42;
	}
};

TCFuture<void> f_HandleErrors()
{
	TCActor<CErrorActor> Actor = fg_Construct<CErrorActor>();

	// Method 1: Using TCAsyncResult
	TCAsyncResult<int32> Result = co_await Actor(&CErrorActor::f_MayFail, true).f_Wrap();

	if (!Result)
	{
		DConErrOut("Error: {}\n", Result.f_GetExceptionStr());
		co_return {};
	}

	DConOut("Success: {}\n", *Result);

	// Method 2: Let exception propagate, the TCFuture of this function will be resolved with the error
	int32 Value = co_await Actor(&CErrorActor::f_MayFail, true);
	DConOut("Value: {}\n", Value);

	co_return {};
}
```

### Distributed Actors

```cpp
// Define distributed interface
class CMyServiceInterface : public CActor
{
public:
	static constexpr ch8 const *mc_pDefaultNamespace = "com.company/MyService";

	enum : uint32
	{
		EProtocolVersion_Min = 0x101,
		EProtocolVersion_Current = 0x101
	};

	CMyServiceInterface()
	{
		// Publish functions for remote access
		DPublishActorFunction(CMyServiceInterface::f_ProcessData);
	}

	virtual TCFuture<CStr> f_ProcessData(CStr _Input) = 0;
};

// Implement service
class CMyService : public CActor
{
public:
	// Delegated implementation
	struct CServiceImpl : public CMyServiceInterface
	{
		TCFuture<CStr> f_ProcessData(CStr _Input) override
		{
			co_return m_pThis->fp_ProcessInternal(_Input);
		}

		DDelegatedActorImplementation(CMyService);
	};

	TCFuture<void> f_Publish()
	{
		// Publish service for remote access
		co_await m_ServiceInterface.f_Publish<CMyServiceInterface>(fg_GetDistributionManager(), this, 10.0);

		co_return {};
	}

private:
	CStr fp_ProcessInternal(CStr const &_Input)
	{
		return "Processed: {}"_f << _Input;
	}

	TCDistributedActorInstance<CServiceImpl> m_ServiceInterface;
};

// Client subscribing to service
TCFuture<void> f_UseRemoteService()
{
	// Subscribe to remote services
	auto RemoteServices = co_await g_TrustManager->f_SubscribeTrustedActors<CMyServiceInterface>();

	co_await RemoteServices.f_OnActor(g_ActorFunctor / [](TCDistributedActor<CMyServiceInterface> _Service, CTrustedActorInfo _Info) -> TCFuture<void>
		{
			// Call remote service
			CStr Result = co_await _Service.f_CallActor(&CMyServiceInterface::f_ProcessData)("Hello");

			DConOut("Remote result: {}\n", Result);
			co_return {};
		}
		, g_ActorFunctor / [](TCWeakDistributedActor<CActor> _Actor, CTrustedActorInfo _Info) -> TCFuture<void>
		{
			DConOut("Service disconnected\n");
			co_return {};
		}
	);

	co_return {};
}
```

### Parallel Execution

```cpp
// Dispatch work to thread pool
TCFuture<void> f_ParallelWork()
{
	// Get blocking actor for I/O operations
	auto BlockingActorCheckout = fg_BlockingActor();

	// Dispatch blocking operation
	CStr FileContent = co_await
		(
			g_Dispatch(BlockingActorCheckout) / []() -> CStr
			{
				// This runs on thread pool, safe for blocking
				return CFile::fs_ReadStringFromFile("/path/to/file");
			}
		)
	;

	// Parallel foreach
	TCVector<int32> Data = {1, 2, 3, 4, 5};
	co_await fg_ParallelForEach
		(
			Data
			, [](int32 &_Value) -> TCFuture<void>
			{
				_Value *= 2;
				co_return {};
			}
		)
	;

	co_return {};
}
```

### Actor Destruction

```cpp
class CCleanupActor : public CActor
{
protected:
	// Override for async cleanup
	TCFuture<void> fp_Destroy() override
	{
		DConOut("Cleaning up...\n");

		// Perform async cleanup
		co_await fp_SaveState();
		co_await fp_CloseConnections();

		co_return {};
	}

private:
	TCFuture<void> fp_SaveState()
	{
		// Save state before destruction
		co_return {};
	}

	TCFuture<void> fp_CloseConnections()
	{
		// Close network connections
		co_return {};
	}
};

TCFuture<void> f_ManualDestroy()
{
	TCActor<CCleanupActor> Actor = fg_Construct<CCleanupActor>();

	// Manual destruction
	auto Result = co_await fg_Move(Actor).f_Destroy().f_Wrap();
	if (!Result)
		DConErrOut("Destroy failed: {}\n", Result.f_GetExceptionStr());

	// Actor also destroyed automatically when TCActor goes out of scope
	co_return {};
}
```

## Common Patterns

### Actor Call Syntax

```cpp
// Basic call with result
int32 Value = co_await MyActor(&CMyActor::f_Function, Param1, Param2);

// Call with error handling
TCAsyncResult<int32> Result = co_await MyActor(&CMyActor::f_Function, Param).f_Wrap();
if (!Result)
{
	// Handle error
}

// Discard result
MyActor(&CMyActor::f_Function).f_DiscardResult();

// With timeout
int32 Value = co_await MyActor(&CMyActor::f_Function).f_Timeout(5.0, "Operation timed out");

// Direct callback (without coroutines)
MyActor(&CMyActor::f_Function) > [](TCAsyncResult<int32> _Result)
	{
		// Handle result
	}
;
```

### Promise/Future Patterns

```cpp
// Creating promise/future pair
TCPromise<int32> Promise;
TCFuture<int32> Future = Promise.f_GetFuture();

// Setting result
Promise.f_SetResult(42);
// or
Promise.f_SetException(DMibErrorInstance("Failed"));

// Promise with callback
MyActor(&CMyActor::f_Function) > Promise / [Promise](int32 _Value)
	{
		// Exception handling done automatically
		Promise.f_SetResult(_Value * 2);
	}
;
```

### Actor Functors

```cpp
// Create actor functor
auto Functor = g_ActorFunctor / [this](int32 _Value) -> TCFuture<void>
	{
		DConOut("Received: {}\n", _Value);
		co_return {};
	}
;

// With subscription for cleanup
auto Functor = g_ActorFunctor
	(
		g_ActorSubscription / [this]() -> TCFuture<void>
		{
			// Called when functor goes out of scope
			co_await fp_Cleanup();
			co_return {};
		}
	)
	/ [this](int32 _Value) -> TCFuture<void>
	{
		co_await fp_HandleValue(_Value);
		co_return {};
	}
;
```

### Resource Cleanup Helpers

```cpp
// Ensure an actor is destroyed even if the coroutine exits early
TCActor<CFileTransferSend> Upload = fg_ConstructActor<CFileTransferSend>(_Path);
co_await fg_AsyncDestroy(Upload); // Schedule destruction when co-routine goes out of scope

// Destroy by value (functor/lambda) after use
co_await fg_AsyncDestroy
	(
		[&AsyncResult]() -> TCFuture<void>
		{
			co_await fg_Move(AsyncResult).f_Destroy();
			co_return {};
		}
	)
;

// Re-validate pointers after suspension
TCFuture<void> f_Process(CStr _Key)
{
	CValue *pValue = nullptr;

	co_await fg_OnResume
		(
			[&]() -> CExceptionPointer
			{
				pValue = mp_Items.f_FindEqual(_Key);
				if (!pValue)
					return DMibErrorInstance("Value disappeared");

				return {};
			}
		)
	;

	co_await pValue->f_DoWork();
	co_return {};
}
```

- Use the `fg_AsyncDestroy` helper instead of manual `g_OnScopeExit` plumbing when an actor/functor needs structured teardown.
- Schedule the helper before the first suspension and capture by reference — the functor runs while the coroutine frame is still alive, so moving the resource into the co-routine frame. After the first suspension of the cleanup function the references will be invalid.
- These helpers schedule destruction on the owning actor.
- Pair `fg_OnResume` with any pointer captures when the coroutine is going to suspend before dereferencing actor-owned data. While the coroutine is cancelled if the actor dies, other actor calls can mutate or erase those structures during the suspension, so re-validation on resume avoids stale references.

## Safety Considerations

### Coroutine Safety

```cpp
// INVALID: TCFuture coroutines cannot take reference parameters (compile error)
TCFuture<void> f_Invalid(CStr const &_Str);

// SAFE: Pass by value (preferred for all TCFuture coroutines)
TCFuture<void> f_Safe(CStr _Str)
{
	co_await fg_Timeout(1.0);
	DConOut("{}\n", _Str); // Safe
	co_return {};
}

// UNSAFE: Reference parameters after suspension
TCUnsafeFuture<void> f_Unsafe(CStr const &_Str)
{
	co_await fg_Timeout(1.0);
	DConOut("{}\n", _Str); // _Str may be invalid!
	co_return {};
}

// SAFE (for TCUnsafeFuture): copy before the first suspension
TCUnsafeFuture<void> f_SafeStore(CStr const &_Str)
{
	CStr Copy = _Str; // Store before suspension
	co_await fg_Timeout(1.0);
	DConOut("{}\n", Copy); // Safe
	co_return {};
}
```

### Thread Safety

```cpp
// UNSAFE: Accessing actor internals outside actor
TCActor<CMyActor> Actor;
// Actor->m_Value = 5; // Compile error - good!

// SAFE: All access through actor calls
co_await Actor(&CMyActor::f_SetValue, 5);

// UNSAFE: Capturing 'this' in blocking dispatch
auto BlockingActorCheckout = fg_BlockingActor();
co_await
	(
		g_Dispatch(BlockingActorCheckout) / [this]()
		{
			m_Value++; // Race condition!
		}
	)
;

// SAFE: No shared state in blocking dispatch
int32 LocalCopy = m_Value;
auto BlockingActorCheckout = fg_BlockingActor();
int32 Result = co_await
	(
		g_Dispatch(BlockingActorCheckout) / [LocalCopy]()
		{
			return LocalCopy + 1; // Safe
		}
	)
;
m_Value = Result;
```

### Error Handling with Coroutines

```cpp
// INCORRECT: co_await in catch block (compilation error)
try
{
	Json = CEJsonSorted::fs_FromString(Input);
}
catch (NException::CException const &_Exception)
{
	co_await _pCommandLine->f_StdErr("Error: {}\n"_f << _Exception); // ERROR!
	co_return 1;
}

// CORRECT: Use g_CaptureExceptions
{
	auto CaptureScope = co_await (g_CaptureExceptions % "Error parsing JSON");
	Json = CEJsonSorted::fs_FromString(Input);
}

// INCORRECT: Wrong operator precedence with % and co_await
auto BlockingActorCheckout = fg_BlockingActor();
CStr Result = co_await
	(
		g_Dispatch(BlockingActorCheckout) / [Path]() -> CStr
		{
			return CFile::fs_ReadStringFromFile(Path);
		}
	) % "Error reading file"  // ERROR: % applied after co_await
;

// CORRECT: Parenthesize the % operator
auto BlockingActorCheckout = fg_BlockingActor();
CStr Result = co_await
	(
		g_Dispatch(BlockingActorCheckout) / [Path]() -> CStr
		{
			return CFile::fs_ReadStringFromFile(Path);
		}
		% "Error reading file"  // Correct: % applied to future before co_await
	)
;

```

## Testing

```bash
# Run all concurrency tests
/opt/Deploy/Tests/RunAllTests --paths '["Malterlib/Concurrency*"]'

# Run specific test suites
/opt/Deploy/Tests/RunAllTests --paths '["Malterlib/Concurrency/Actor*"]'
/opt/Deploy/Tests/RunAllTests --paths '["Malterlib/Concurrency/Coroutines*"]'
/opt/Deploy/Tests/RunAllTests --paths '["Malterlib/Concurrency/DistributedActor*"]'
```

## Dependencies

The Concurrency module depends on:
- **Core** - Basic types and utilities
- **Thread** - Threading primitives
- **Storage** - Memory management and smart pointers
- **Function** - Function wrappers and delegates
- **Exception** - Exception handling
- **Container** - Data structures
- **Database** - For distributed app persistence (indirect)
- **Web** - For distributed communication (indirect)
- **Cryptography** - For secure distributed communication (indirect)

## Configuration

Build configuration properties (UserSettings.MSettings):
```cpp
// Enable debug features
MalterlibConcurrency_DebugActorCallstacks true  // Track call stacks
MalterlibConcurrency_DebugBlockDestroy true     // Debug block destruction
MalterlibConcurrency_DebugFutures true          // Future reference debugging
MalterlibConcurrency_DebugUnobservedException true // Unobserved exceptions
MalterlibConcurrency_DebugSubscriptions true    // Subscription logging
```

## Common Pitfalls

1. **Blocking in Actors**: Never block in actor code - use `fg_BlockingActor()` for I/O
2. **Dangling References**: Use value semantics or ensure lifetime with subscriptions
3. **Unobserved Results**: Always observe async results to catch exceptions
4. **TCFuture References**: Reference parameters are rejected by the compiler
5. **TCFutureUnsace References**: Always pass by value or move data before the first `co_await`
6. **Cross-Actor Access**: Never access actor internals directly
7. **Forgotten co_return**: Always end coroutines with `co_return {};` for void
8. **Race Conditions**: Don't share mutable state between actors without synchronization
9. **Deadlocks**: Avoid circular actor dependencies
10. **co_await in catch blocks**: Cannot use `co_await` in catch handlers - use `g_CaptureExceptions` instead
11. **Exception message operator precedence**: When using `% "message"` with `co_await`, parenthesize properly: `co_await ((...) % "message")`

## Advanced Features

### Weak Actor References
```cpp
TCWeakActor<CMyActor> WeakRef = Actor;
if (auto StrongRef = WeakRef.f_Lock())
	co_await StrongRef(&CMyActor::f_Function);
```

### Async Generators
```cpp
TCAsyncGenerator<int32> f_GenerateNumbers()
{
	for (int32 i = 0; i < 10; ++i)
	{
		co_yield i;
		co_await fg_Timeout(0.1);
	}
}

TCFuture<void> f_ConsumeNumbers()
{
	for (auto iIterator = co_await f_GenerateNumbers().f_GetIterator(); iIterator;  co_await ++iIterator)
	{
		DConOut("Number: {}\n", *iIterator);
	}

	co_return {};
}
```

### Performance Optimization
- Use `f_DiscardResult()` when you don't need the result
- Batch operations when possible to reduce actor calls
- Use `TCFutureVector` for parallel operations
- Consider actor granularity - too many actors add overhead

<!-- End include: Malterlib/Concurrency/CLAUDE.md -->

<!-- End include: Malterlib/Core/CLAUDE.md -->

<!-- End include: CLAUDE.md -->
