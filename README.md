# Siv3D Zig Build

Build Siv3D App with `zig build`.

This repository explores using Zig's build system to build a Siv3D application without CMake.
The current proof of concept targets x86_64 macOS 13 or later, x86_64 glibc-based Linux, and
x86_64 Windows with the MSVC ABI. Zig downloads and caches a pinned Siv3D SDK archive for the
selected platform automatically.

## Requirements

- Zig 0.16.0
- macOS: Xcode Command Line Tools, plus an Intel Mac or Rosetta 2 on an Apple Silicon Mac
- Linux: glibc, libstdc++, a system C++ compiler, pkg-config, and the Siv3D system dependencies
- Windows: Visual Studio 2022 17.10 or later with MSVC and the Windows SDK

The prebuilt Linux SDK is built and tested on Ubuntu 22.04 with GCC 11. Other glibc-based Linux
distributions may work when the equivalent system dependencies are installed. See the
[Siv3D Linux Builds](https://github.com/Ryoga-exe/Siv3D-linux-builds#system-dependencies-on-ubuntu)
documentation for the Ubuntu package list. musl-based distributions such as Alpine Linux are not
currently supported. OpenCV, FFmpeg, and SoundTouch are pinned and bundled in the Linux SDK, so
system packages for them are not required. Set `CXX` when the system C++ compiler is not available
as `c++` or `g++`.

## Build

```sh
zig build
```

On macOS, the app bundle is generated at `zig-out/Siv3DTest.app`.
On Linux and Windows, the executable and runtime resources are generated under `zig-out/bin`.
On Linux, the bundled FFmpeg and SoundTouch shared libraries are also copied to `zig-out/bin`, and
the executable uses an `$ORIGIN` RUNPATH to load them from that directory.
To build and run it:

```sh
zig build run
```

The default optimization mode is `Debug`. For a release build, choose one of Zig's release
optimization modes explicitly. `ReleaseFast` is a good default for normal use:

```sh
zig build -Doptimize=ReleaseFast
```

The `run` step accepts the same option:

```sh
zig build run -Doptimize=ReleaseFast
```

Other available modes are `ReleaseSafe` and `ReleaseSmall`. The generated app is unsigned and is
intended for local development. Distribution to other machines requires the appropriate platform
packaging workflow, such as code-signing and notarization on macOS.

To select a platform explicitly:

```sh
zig build -Dtarget=x86_64-macos
zig build -Dtarget=x86_64-linux-gnu
zig build -Dtarget=x86_64-windows-msvc
```

## Scope

The Siv3D SDK URL and content hash are pinned in `build.zig.zon`. Zig compiles the C++23 source,
links the prebuilt Siv3D libraries, generates the app metadata or Windows resources, and assembles
a runnable app. Platform SDK dependencies are marked lazy so unrelated SDK archives are not fetched
when building for a different platform.

Linux uses the unofficial prebuilt SDK from
[Siv3D Linux Builds](https://github.com/Ryoga-exe/Siv3D-linux-builds). The SDK contains the Release
version of `libSiv3D.a`, which is used for every Zig optimization mode. Linux builds currently run
only on an x86_64 Linux host because they use the host's libstdc++ and pkg-config dependencies.

Windows Debug builds link the Siv3D debug libraries and the statically linked MSVC Debug CRT.
They must run on a Windows host because the Debug CRT is discovered from the local MSVC
installation. The other optimization modes use the Siv3D release libraries and static release CRT.
