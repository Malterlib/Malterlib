# Malterlib

*C++ tooling that fits together — one toolchain, one build system, one standard library, one philosophy.*

## Getting started

Drop into an empty directory and bootstrap a project:

```bash
curl -fLO https://raw.githubusercontent.com/Malterlib/Malterlib/master/mib
chmod +x mib
./mib init
```

`./mib init` is the whole installer. It fetches Clang, lldb, clangd, the Malterlib core repositories and the build system tools under your project, scaffolds an `.MBuildSystem` file, and drops in templates for `.gitignore`, `.vscode/`, and `CLAUDE.md`. Nothing lands outside the project directory and your `~/.Malterlib` cache — no global installs, no package manager.

When it finishes, follow the next-step instructions it prints, then run `./mib generate` to produce the default Tests workspace. `./mib --help` lists the rest of the subcommands.

The scaffold also generates tuned `CLAUDE.md` and `AGENTS.md` files — these aren't placeholders, they're framework-specific instructions that teach your coding agent Malterlib's conventions, naming, module layout, and async patterns, so it doesn't have to reverse-engineer the framework from scratch. A perfectly reasonable first move is to point your favourite agent at the fresh repo and ask it to build something. For example:

```
Create a distributed app tool that reports the weather.
* Use the table renderer.
* Detect the location from the exit IP.
* Create a new workspace, because this repository was just created.
```

## Editor and tooling integration

Malterlib's naming conventions and build-file dialect really pay off with an editor that understands them. Two paths:

- **Recommended:** [Unbroken Code](https://github.com/Unbroken/UnbrokenCode/releases/latest) — a VS Code fork with the Malterlib extensions baked in. You get semantic coloring keyed to the naming prefixes, syntax highlighting for `.MTarget` / `.MConfig` / etc., status-bar pickers for generator / workspace / configuration / target, lldb debug integration, and the Malterlib-flavoured clangd. Grab the latest release and you're done.
- **Any other VS Code fork:** the same release page has a *Bundled Extensions Downloads* section. Install those into your fork of choice and you keep the language support, build system tasks, and problem matchers — just without Unbroken Code's editor-level tweaks.

## Supported platforms

- **macOS** — x64, arm64
- **Windows** — x64, arm64
- **Linux** — x64, arm64, x86

Cross-compiling between architectures on the same platform always works — on Linux that's handled by per-architecture SDKs that ship with the toolchain, so an x64 Linux host can build arm64 or x86 binaries without anything extra. Cross-*platform*, the currently supported combination is **macOS host → Linux target**: the Linux SDKs travel with Malterlib, so you can produce Linux binaries from a Mac without a Linux machine or container.

## Building

`./mib build <Workspace>` generates the build files (if they're stale) and builds. By default, intermediate build artifacts go to `~/.CompiledFiles` and finished applications end up in `~/.Deploy`.

For example, to build the test suite and run it:

```bash
./mib build Tests
cd ~/.Deploy/Tests
./RunAllTests
```

`./mib test` is the same thing in one step. `./mib --help build` lists the rest of the build flags (target overrides, single-target builds, platform/architecture/configuration switches).

### Configuring your build

Per-project build switches live in `BuildSystem/Default/UserSettings.MSettings`. The file is heavily commented and most options are already written out — uncomment the ones you want.

By default the build targets your current host's platform and architecture in Debug configuration — which is what you want most of the time. To deviate from that — to cross-compile, swap architecture, or build Release — set the `Single*` properties near the top of the file:

```
SingleArchitecture "arm64"   // Override the default architecture
SingleConfiguration "Debug"  // Override the default configuration
SinglePlatform "macOS"       // Override the default platform
```

The same file also exposes toggles for sanitizers, the memory-manager flavour and its debug instrumentation, ref-count and leak debugging, repository sync scope, code-signing identities, and individual module enables. Save your edits and run `./mib generate` again to regenerate the workspace.

## Why this exists

A "standard" C++ project doesn't fit together beautifully. It doesn't just *Work*. You assemble it: a build system that doesn't know about your IDE, a compiler that disagrees with the other compiler you also support, a package manager someone wrote a thesis about, and a standard library whose template errors you've learned to skim like horoscopes. None of those things talk to each other. Each is somebody else's problem.

Malterlib is what happens when you decide all of it is your problem.

### One toolchain, everywhere

C++ has many compilers. This has been sold as a strength for as long as I've been writing it. I spent twenty years maintaining MSVC support alongside Clang and finally stopped pretending the freedom of choice was free. Rust has one compiler. Go has one compiler. Both languages move faster than C++ on the things that actually matter to a working developer, and they do it because nobody is shipping workarounds for the third-place implementation.

LLVM won. Malterlib ships Clang, lldb, and clangd — the same versions on every platform. You get the newest C++ features on the oldest target OS you care about. Your colleague's machine compiles your code identically to yours. CI matches both. Not because everyone agreed on a config — because there is only one.

The executables you build come out statically linked with no system dependencies. Like a Rust binary, they run wherever you drop them — no "but does the target box have the right libstdc++?" no chasing glibc versions, no install scripts. You ship a file.

### A build system that doesn't apologize

The build system is declarative and fast. Huge projects generate in seconds instead of minutes. Detecting *nothing changed, no work to do* takes under a tenth of a second. CMake's only real claim is that it became standard; once you stop paying that tax you don't miss it.

Because the build is declarative — JSON-shaped values, not imperative scripts — tooling can actually reason about it. The IDE knows it. Refactors know it. Caches know it. Repository management is built in, because in practice "the build" and "the dependencies" are the same problem. There is no `if compiler_supports_X` dance: a target either supports something or it doesn't, and the answer is known at generation time.

If you have an existing CMake project you can't escape, Malterlib can import it and cache the result. One person pays the CMake tax once, checks the cache in, and the rest of the team can forget it ever happened.

### A standard library that fits the language you're already writing

Yes, this part is going to upset people. Malterlib uses its own standard library, not the STL.

The design philosophy is *don't pay for what you don't use* — more aggressive than C++ itself. Naming is coherent end-to-end so you aren't dragging `snake_case` through the rest of your code. Template implementations are written for humans to read.

The containers come out smaller than every STL implementation because we made different tradeoffs. A `TCSet` or `TCMap` node, for example, doesn't carry a parent pointer — every STL tree does. The cost lives in iterator invalidation: any insert or remove invalidates all iterators into the container, where STL maps and sets only invalidate iterators to elements that were actually removed.

The headline feature isn't the containers, though. It's the concurrency layer. Async work in C++ is normally a minefield of threading correctness bugs; Malterlib's actor and coroutine system makes it boring. You define an interface, call it like a function, await a future. The same interface works locally and across the network — RPC is a property of the call site, not a separate framework bolted on.

Underneath all of that sits the memory manager. It's a concurrent allocator with per-thread arenas, worst-case fragmentation kept under 12.5%, and a background cleanup pass that lets caches stay hot without permanently inflating your RSS. It replaces the system allocator on every OS Malterlib supports — with the same implementation. Your program allocates identically, with identical performance, on macOS, Linux, and Windows. "Works on my machine" stops including the malloc.

And if none of that convinces you: the STL is fully supported, with all the cross-platform portability fixes already in place. Use it, mix it, ignore Malterlib's containers entirely. Nothing here forces a choice on you.

### Forking as the default, not the emergency

Take destiny into your own hands.

Every dependency Malterlib pulls in is a git repository you can fork, branch, and patch as easily as your own code. Repository management exists specifically so a forked workflow stays manageable across dozens of sub-repos. The point isn't that you'll fork everything — it's that the day you need to, you aren't blocked, you aren't waiting on a maintainer, and you aren't shipping a binary blob you didn't compile.

## Contributing

Pull requests are welcome. A few notes before you open one:

- **Sign the CLA.** Malterlib uses a contributor licence agreement to keep the project's licence chain clean. As an individual, just open a PR — the GitHub CLA bot drops a signing link in the conversation, and once you've accepted, future PRs from the same account pass automatically. Companies contributing on behalf of employees sign a separate entity agreement by emailing **cla@malterlib.org**. The full instructions, including what to do when rights are owned by an employer or third party, live in [`Documentation/CLA-INSTRUCTIONS.md`](Documentation/CLA-INSTRUCTIONS.md).
- **Match the existing conventions.** Naming, formatting, and module structure are documented in the `CLAUDE.md` files at the repository root and inside each module; `Malterlib/Core/CLAUDE.md` is the entry point. The generated `AGENTS.md` consolidates the same material in one place.
- **Run the tests.** `./mib test` builds and runs the suite — please make sure it passes before sending a PR.

Bug reports, feature ideas, and questions go in GitHub issues. If you want to discuss something without it being treated as a contribution under the CLA, mark the message **"Not a Contribution"** (the CLA instructions explain why that wording matters).

## License

Malterlib is licensed under [Apache 2.0 with the LLVM Exception](LICENSE) — the same license LLVM, Clang, and libc++ ship under. It's the deliberate, no-asterisks answer to "can I ship this in my product?": yes.

While Malterlib's own code requires no attribution in shipped binaries (the LLVM Exception waives that explicitly), the third-party libraries it pulls in might. The always-on set is **BoringSSL**, **curl**, **zlib**, **zstd**, **lmdb** and **HIDAPI**; some modules add **libarchive**, or **libpng**. All are permissively licensed (BSD-, MIT-, zlib-, ISC-, and OpenLDAP-style) — no copyleft, no source-disclosure clauses — but most of those licences do ask you to reproduce a short copyright notice in your product's credits. Each licence text lives in `External/<name>/`.
