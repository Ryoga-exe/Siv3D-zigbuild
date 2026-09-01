# Siv3D Zig Build

Build Siv3D App with `zig build`.

This repository explores using Zig's build system to build a Siv3D application without CMake.
The current proof of concept targets x86_64 macOS 13 or later and x86_64 Windows with the MSVC ABI.
Zig downloads and caches the official Siv3D SDK for the selected platform automatically.

## Requirements

- Zig 0.16.0
- macOS: Xcode Command Line Tools, plus an Intel Mac or Rosetta 2 on an Apple Silicon Mac
- Windows: Visual Studio 2022 17.10 or later with MSVC and the Windows SDK

## Build

```sh
zig build
```

On macOS, the app bundle is generated at `zig-out/Siv3DTest.app`.
On Windows, the executable and runtime DLLs are generated under `zig-out/bin`.
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

To cross-select a platform explicitly:

```sh
zig build -Dtarget=x86_64-macos
zig build -Dtarget=x86_64-windows-msvc
```

## Scope

The Siv3D SDK URL and content hash are pinned in `build.zig.zon`. Zig compiles the C++23 source,
links the prebuilt Siv3D libraries, generates the app metadata or Windows resources, and assembles
a runnable app. Platform SDK dependencies are marked lazy so unrelated SDK archives are not fetched
when building for a different platform.

Windows Debug builds link the Siv3D debug libraries and the statically linked MSVC Debug CRT.
They must run on a Windows host because the Debug CRT is discovered from the local MSVC
installation. The other optimization modes use the Siv3D release libraries and static release CRT.
