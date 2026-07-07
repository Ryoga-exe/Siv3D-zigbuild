# Siv3D Zig Build

Build Siv3D App with `zig build`.

This repository explores using Zig's build system to build a Siv3D application without CMake.
The current proof of concept targets x86_64 macOS 13 or later. Zig downloads and caches the official Siv3D SDK automatically.

## Requirements

- Zig 0.16.0
- Xcode Command Line Tools
- An Intel Mac, or Rosetta 2 on an Apple Silicon Mac

## Build

```sh
zig build
```

The app bundle is generated at `zig-out/Siv3DTest.app`. To build and open it:

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
intended for local development. Distribution to other Macs requires an appropriate code-signing
and notarization workflow.

## Scope

The Siv3D SDK URL and content hash are pinned in `build.zig.zon`. Zig compiles the C++23 source,
links the prebuilt Siv3D libraries, generates the app metadata, and assembles a runnable macOS app
bundle.
