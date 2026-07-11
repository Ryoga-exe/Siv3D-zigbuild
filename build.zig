const std = @import("std");
const builtin = @import("builtin");

const app_name = "Siv3DTest";
const app_zon_version = @import("build.zig.zon").version;
const app_version = std.SemanticVersion.parse(app_zon_version) catch
    @compileError("build.zig.zon .version must be a valid semantic version");
const minimum_macos_version = std.SemanticVersion{
    .major = 13,
    .minor = 0,
    .patch = 0,
};
const bundle_identifier = "com.github.ryoga-exe.siv3d-zigbuild";
const bundle_path = app_name ++ ".app/Contents";

const cpp_sources = [_][]const u8{
    "src/Main.cpp",
};

const cxx_flags = [_][]const u8{
    "-std=c++23",
};

const windows_cxx_flags = [_][]const u8{
    "-std=c++23",
    "-fms-compatibility-version=19.40",
    "-fms-runtime-lib=static",
    // The Windows SDK release libraries are linked for every Zig optimize mode.
    // Siv3D debug libraries require MSVC debug CRT discovery that Zig does not wire here yet.
    "-DNDEBUG",
};

const macos_siv3d_libraries = [_][]const u8{
    "libSiv3D.a",
    "boost/libboost_filesystem.a",
    "freetype/libfreetype.a",
    "harfbuzz/libharfbuzz.a",
    "libgif/liblibgif.a",
    "libjpeg-turbo/libturbojpeg.a",
    "libogg/libogg.a",
    "libpng/libpng16.a",
    "libtiff/libtiff.a",
    "libvorbis/libvorbis.a",
    "libvorbis/libvorbisenc.a",
    "libvorbis/libvorbisfile.a",
    "libwebp/libwebp.a",
    "opencv/libopencv_core.a",
    "opencv/libopencv_imgcodecs.a",
    "opencv/libopencv_imgproc.a",
    "opencv/libopencv_objdetect.a",
    "opencv/libopencv_photo.a",
    "opencv/libopencv_videoio.a",
    "opus/libopus.a",
    "opus/libopusfile.a",
    "zlib/libzlib.a",
};

const macos_system_libraries = [_][]const u8{
    "curl",
    "objc",
};

const macos_system_frameworks = [_][]const u8{
    "AVFoundation",
    "AppKit",
    "AudioToolbox",
    "CFNetwork",
    "CoreFoundation",
    "CoreGraphics",
    "CoreMedia",
    "CoreServices",
    "CoreText",
    "CoreVideo",
    "Foundation",
    "IOKit",
    "Metal",
    "OpenGL",
    "QuartzCore",
};

const WindowsLibraryGroup = struct {
    directory: []const u8,
    libraries: []const []const u8,
};

const windows_release_library_groups = [_]WindowsLibraryGroup{
    .{ .directory = "", .libraries = &.{"Siv3D.lib"} },
    .{ .directory = "boost", .libraries = &.{"libboost_filesystem-vc143-mt-s-x64-1_83.lib"} },
    .{ .directory = "curl", .libraries = &.{"libcurl.lib"} },
    .{ .directory = "freetype", .libraries = &.{"freetype.lib"} },
    .{ .directory = "glew", .libraries = &.{"glew32s.lib"} },
    .{ .directory = "harfbuzz", .libraries = &.{"harfbuzz.lib"} },
    .{ .directory = "libgif", .libraries = &.{"libgif.lib"} },
    .{ .directory = "libjpeg-turbo", .libraries = &.{"turbojpeg-static.lib"} },
    .{ .directory = "libogg", .libraries = &.{"libogg.lib"} },
    .{ .directory = "libpng", .libraries = &.{"libpng16.lib"} },
    .{ .directory = "libtiff", .libraries = &.{"tiff.lib"} },
    .{ .directory = "libvorbis", .libraries = &.{ "libvorbis_static.lib", "libvorbisfile_static.lib" } },
    .{ .directory = "libwebp", .libraries = &.{"libwebp.lib"} },
    .{ .directory = "Oniguruma", .libraries = &.{"Oniguruma.lib"} },
    .{ .directory = "opencv", .libraries = &.{
        "opencv_core451.lib",
        "opencv_imgcodecs451.lib",
        "opencv_imgproc451.lib",
        "opencv_objdetect451.lib",
        "opencv_photo451.lib",
        "opencv_videoio451.lib",
    } },
    .{ .directory = "opus", .libraries = &.{ "opus.lib", "opusfile.lib" } },
    .{ .directory = "zlib", .libraries = &.{"zlib.lib"} },
};

const windows_resource_dirs = [_][]const u8{
    "engine/font",
    "engine/shader/d3d11",
    "engine/shader/glsl",
    "engine/soundfont",
    "engine/texture",
};

const windows_system_libraries = [_][]const u8{
    "advapi32",
    "bcrypt",
    "comdlg32",
    "d3d11",
    "d3dcompiler",
    "dxgi",
    "gdi32",
    "imm32",
    "mf",
    "mfplat",
    "mfreadwrite",
    "mfuuid",
    "msimg32",
    "ole32",
    "oleaut32",
    "opengl32",
    "rpcrt4",
    "setupapi",
    "shell32",
    "shlwapi",
    "strmiids",
    "user32",
    "uuid",
    "version",
    "winmm",
    "windowscodecs",
    "ws2_32",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = defaultTarget(),
    });
    const optimize = b.standardOptimizeOption(.{});

    const resolved = target.result;
    switch (resolved.os.tag) {
        .macos => buildMacOS(b, target, optimize, resolved),
        .windows => buildWindows(b, target, optimize, resolved),
        else => @panic("this PoC currently supports only x86_64-macos and x86_64-windows-msvc"),
    }
}

fn defaultTarget() std.Target.Query {
    if (builtin.os.tag == .windows) {
        return .{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .msvc,
        };
    }

    return .{
        .cpu_arch = .x86_64,
        .os_tag = .macos,
        .os_version_min = .{ .semver = minimum_macos_version },
    };
}

const CppModuleOptions = struct {
    flags: []const []const u8,
    link_libcpp: ?bool,
};

fn createCppModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    options: CppModuleOptions,
) *std.Build.Module {
    const root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = options.link_libcpp,
    });
    root_module.addCSourceFiles(.{
        .files = &cpp_sources,
        .flags = options.flags,
        .language = .cpp,
    });
    return root_module;
}

fn buildMacOS(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    resolved: std.Target,
) void {
    if (resolved.cpu.arch != .x86_64) {
        @panic("macOS support currently requires x86_64-macos");
    }

    const siv3d_sdk = b.lazyDependency("siv3d_macos", .{}) orelse return;
    const macos_sdk = b.sysroot orelse
        std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &resolved) orelse
        @panic("unable to locate the macOS SDK; install Xcode Command Line Tools");
    b.sysroot = macos_sdk;
    const macos_sdk_root: std.Build.LazyPath = .{ .cwd_relative = macos_sdk };

    const root_module = createCppModule(b, target, optimize, .{
        .flags = &cxx_flags,
        .link_libcpp = true,
    });
    root_module.addSystemIncludePath(siv3d_sdk.path("include"));
    root_module.addSystemIncludePath(siv3d_sdk.path("include/ThirdParty"));
    // Zig resolves the absolute library search path inside --sysroot on Darwin.
    root_module.addLibraryPath(.{ .cwd_relative = "/usr/lib" });
    root_module.addFrameworkPath(macos_sdk_root.path(b, "System/Library/Frameworks"));

    inline for (macos_siv3d_libraries) |library| {
        root_module.addObjectFile(siv3d_sdk.path(b.fmt("lib/macOS/{s}", .{library})));
    }
    inline for (macos_system_libraries) |library| {
        root_module.linkSystemLibrary(library, .{});
    }
    inline for (macos_system_frameworks) |framework| {
        root_module.linkFramework(framework, .{});
    }

    const executable = b.addExecutable(.{
        .name = app_name,
        .root_module = root_module,
        .version = app_version,
    });

    const install_executable = b.addInstallArtifact(executable, .{
        .dest_dir = .{ .override = .{ .custom = bundle_path ++ "/MacOS" } },
    });
    const generated_files = b.addWriteFiles();
    const info_plist = generated_files.add("Info.plist", makeInfoPlist(b));
    const install_plist = b.addInstallFileWithDir(
        info_plist,
        .prefix,
        bundle_path ++ "/Info.plist",
    );
    const install_engine = b.addInstallDirectory(.{
        .source_dir = siv3d_sdk.path("examples/empty/App/engine"),
        .install_dir = .prefix,
        .install_subdir = bundle_path ++ "/Resources/engine",
    });

    const install_step = b.getInstallStep();
    install_step.dependOn(&install_executable.step);
    install_step.dependOn(&install_plist.step);
    install_step.dependOn(&install_engine.step);

    const open = b.addSystemCommand(&.{"/usr/bin/open"});
    open.addArg(b.getInstallPath(.prefix, app_name ++ ".app"));
    open.step.dependOn(install_step);
    const run_step = b.step("run", "Build and open the app bundle");
    run_step.dependOn(&open.step);
}

fn buildWindows(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    resolved: std.Target,
) void {
    if (resolved.cpu.arch != .x86_64 or resolved.abi != .msvc) {
        @panic("Windows support currently requires x86_64-windows-msvc");
    }

    const siv3d_sdk = b.lazyDependency("siv3d_windows_sdk", .{}) orelse return;
    const siv3d_runtime = b.lazyDependency("siv3d_windows_runtime", .{}) orelse return;
    const lib_root = "lib/Windows";
    const runtime_root = "App";

    const root_module = createCppModule(b, target, optimize, .{
        .flags = &windows_cxx_flags,
        // Use the MSVC standard library selected by the target instead of Zig's libc++.
        .link_libcpp = null,
    });
    root_module.addSystemIncludePath(siv3d_sdk.path("include"));
    root_module.addSystemIncludePath(siv3d_sdk.path("include/ThirdParty"));

    for (windows_release_library_groups) |group| {
        const library_dir = if (group.directory.len == 0)
            lib_root
        else
            b.fmt("{s}/{s}", .{ lib_root, group.directory });
        root_module.addLibraryPath(siv3d_sdk.path(library_dir));
        for (group.libraries) |library| {
            root_module.addObjectFile(siv3d_sdk.path(b.fmt("{s}/{s}", .{ library_dir, library })));
        }
    }
    inline for (windows_system_libraries) |library| {
        root_module.linkSystemLibrary(library, .{});
    }

    const generated_files = b.addWriteFiles();
    const rc_file = generated_files.add(
        "Siv3DTest.rc",
        makeWindowsResourceScript(b, siv3d_runtime.path(runtime_root)),
    );
    root_module.addWin32ResourceFile(.{
        .file = rc_file,
        .include_paths = &.{ siv3d_sdk.path("include"), siv3d_runtime.path(runtime_root) },
    });

    const executable = b.addExecutable(.{
        .name = app_name,
        .root_module = root_module,
        .version = app_version,
    });
    executable.subsystem = .Windows;

    const install_executable = b.addInstallArtifact(executable, .{});
    const install_dlls = b.addInstallDirectory(.{
        .source_dir = siv3d_runtime.path(b.fmt("{s}/dll", .{runtime_root})),
        .install_dir = .bin,
        .install_subdir = "dll",
    });

    const install_step = b.getInstallStep();
    install_step.dependOn(&install_executable.step);
    install_step.dependOn(&install_dlls.step);

    const run = b.addSystemCommand(&.{b.getInstallPath(.bin, app_name ++ ".exe")});
    run.step.dependOn(install_step);
    const run_step = b.step("run", "Build and run the executable");
    run_step.dependOn(&run.step);
}

fn makeWindowsResourceScript(b: *std.Build, runtime_app: std.Build.LazyPath) []const u8 {
    const runtime_app_path = runtime_app.getPath(b);
    var buffer = std.array_list.Managed(u8).init(b.allocator);
    for (windows_resource_dirs) |resource_dir| {
        appendWindowsResourceDir(b, &buffer, runtime_app_path, resource_dir);
    }

    const icon_path = b.pathJoin(&.{ runtime_app_path, "icon.ico" });
    std.Io.Dir.accessAbsolute(b.graph.io, icon_path, .{}) catch |err| {
        std.debug.panic("unable to access Siv3D icon '{s}': {s}", .{ icon_path, @errorName(err) });
    };
    buffer.print("100 ICON {s}\n", .{makeRcFileStringLiteral(b, "icon.ico")}) catch @panic("OOM");

    return buffer.toOwnedSlice() catch @panic("OOM");
}

fn appendWindowsResourceDir(
    b: *std.Build,
    buffer: *std.array_list.Managed(u8),
    runtime_app_path: []const u8,
    resource_dir: []const u8,
) void {
    const absolute_dir = b.pathJoin(&.{ runtime_app_path, resource_dir });
    const io = b.graph.io;
    var dir = std.Io.Dir.openDirAbsolute(io, absolute_dir, .{ .iterate = true }) catch |err| {
        std.debug.panic("unable to open Siv3D resource directory '{s}': {s}", .{ absolute_dir, @errorName(err) });
    };
    defer dir.close(io);

    var walker = dir.walk(b.allocator) catch @panic("OOM");
    defer walker.deinit();

    while (walker.next(io) catch |err| {
        std.debug.panic("unable to walk Siv3D resource directory '{s}': {s}", .{ absolute_dir, @errorName(err) });
    }) |entry| {
        if (entry.kind != .file) continue;

        const relative_path = b.pathJoin(&.{ resource_dir, entry.path });
        buffer.print("{s} FILE {s}\n", .{
            makeRcNameStringLiteral(b, relative_path),
            makeRcFileStringLiteral(b, relative_path),
        }) catch @panic("OOM");
    }
}

fn makeRcNameStringLiteral(b: *std.Build, path: []const u8) []const u8 {
    const normalized = std.mem.replaceOwned(u8, b.allocator, path, "\\", "/") catch @panic("OOM");
    return b.fmt("\"{s}\"", .{normalized});
}

fn makeRcFileStringLiteral(b: *std.Build, path: []const u8) []const u8 {
    const windows_path = std.mem.replaceOwned(u8, b.allocator, path, "/", "\\") catch @panic("OOM");
    const escaped = std.mem.replaceOwned(u8, b.allocator, windows_path, "\\", "\\\\") catch @panic("OOM");
    return b.fmt("\"{s}\"", .{escaped});
}

fn makeInfoPlist(b: *std.Build) []const u8 {
    return b.fmt(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        \\<plist version="1.0">
        \\<dict>
        \\    <key>CFBundleDevelopmentRegion</key>
        \\    <string>en</string>
        \\    <key>CFBundleExecutable</key>
        \\    <string>{s}</string>
        \\    <key>CFBundleIdentifier</key>
        \\    <string>{s}</string>
        \\    <key>CFBundleInfoDictionaryVersion</key>
        \\    <string>6.0</string>
        \\    <key>CFBundleName</key>
        \\    <string>{s}</string>
        \\    <key>CFBundlePackageType</key>
        \\    <string>APPL</string>
        \\    <key>CFBundleShortVersionString</key>
        \\    <string>{f}</string>
        \\    <key>CFBundleVersion</key>
        \\    <string>1</string>
        \\    <key>LSMinimumSystemVersion</key>
        \\    <string>{f}</string>
        \\    <key>NSHighResolutionCapable</key>
        \\    <true/>
        \\</dict>
        \\</plist>
        \\
    , .{ app_name, bundle_identifier, app_name, app_version, minimum_macos_version });
}
