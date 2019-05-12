# Malterlib

C++ development framework optimized for an agile community

## Run latest C++ standard everywhere
- [x] Use latest C++ versions on all supported OSes
 - [x] Requiring static linking allows us to largly ignore ABI compatibility
- [x] Tracks latest compiler versions only
 - [x] Clang with libc++ on macOS and Linux
 - [x] MSVC on Windows
- [x] Targets most popular platforms
 - [x] macOS 10.5 or later
 - [x] Linux 2.6 or later
 - [x] Windows XP or later
 - [ ] iOS
 - [ ] Android

## Package management
- [x] Dependencies through git references
- [x] Designed for trunk based development
 - [x] Tools for reconciling your local changes with upstream
 - [ ] New upstream versions detected through git changes in upstream
 - [ ] Handle dependency repositories through git hooks
 - [ ] Automatic refactoring infrastructure to allow library interface changes
- [ ] Tools for easily forking a dependency for your project/team
 - [ ] GitHub
 - [ ] GitLab
 - [ ] BitBucket
- [ ] Binary caches for builds
 - [ ] Easily setup local (for security) infrastructure
- [ ] Trust your third party dependencies
 - [ ] Code review with public key signatures for git hashes


## Build system generation
- [x] Generates build systems optimized for target tooling
- [x] Xcode
- [x] Visual Studio
- [x] Doxygen documentation generation
- [ ] ninja

## Async concurrent programming model
- [x] Safe async programming
- [x] Coroutine support
- [x] Cross process/machine secure communication
 - [x] Transparent to programmer

## Cross platform abstractions
- [x] File system
- [x] Daemon management
- [x] Threading
- [x] Process management (launching, killing, etc)
- [x] User management (partial)
- [x] Dll/so/dylib
- [x] Console
- [x] Virtual memory management
- [x] Crash dump generation
- [x] Stack tracing and debug symbols
- [x] Environment variables
- [x] UUID generation
- [x] High entropy random generation
- [x] User password storage (Keychain etc)

## Libraries for commonly used functionality
Support but don't rely on std c++ library to be able to move faster.

- [x] Intrusive containers
 - [x] Optimized for low memory usage (usually gives better performance)
 - [x] Easy to understand interface with member variables
 - [x] Singly linked list
 - [x] Doubly linked list
 - [x] AVL tree
- [x] Containers
 - [x] Optimized for low memory usage (usually gives better performance)
 - [x] Bit array
 - [x] Hierarchical bit arrays
 - [x] Linked list
 - [x] Map
 - [x] Set
 - [x] Vector
 - [x] Paged byte vector
 - [x] Regions
 - [x] Tree container (registry)
- [x] Strings
 - [x] Encodings
  - [x] UTF8
  - [x] UTF16
  - [x] UTF32
  - [x] Windows-1252
  - [x] Other encoding conversions using OS support
 - [x] Different containers
  - [x] Dynamic
  - [x] Static
  - [x] Secure (Zero memory at destruction)
 - [x] Formatting
 - [x] Parsing
 - [x] Algorithms
- [x] Bit manipulation
- [x] Memory debugging
- [x] Cloud orchestration and management
- [x] JSON and EJSON
- [x] Command line parsing
- [x] Console color generation and parsing
- [x] Compression
- [x] Encryption (using BoringSSL)
- [x] Contracts
- [x] Testing
- [x] Networking
- [x] Web
- [x] Websockets
- [o] HTTP client
- [o] HTTP server
- [ ] User interface

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

What things you need to install the software and how to install them

```
Give examples
```

### Installing

A step by step series of examples that tell you how to get a development env running

Say what the step will be

```
Give the example
```

And repeat

```
until finished
```

End with an example of getting some data out of the system or using it for a little demo

## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc
