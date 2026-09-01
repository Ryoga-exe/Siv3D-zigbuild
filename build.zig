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

const windows_release_cxx_flags = [_][]const u8{
    "-std=c++23",
    "-fms-compatibility-version=19.40",
    "-fms-runtime-lib=static",
    "-DNDEBUG",
};

const windows_debug_cxx_flags = [_][]const u8{
    "-std=c++23",
    "-fms-compatibility-version=19.40",
    "-fms-runtime-lib=static_dbg",
    "-D_DEBUG",
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

const WindowsLibrary = struct {
    release: []const u8,
    debug: []const u8,
};

const WindowsLibraryGroup = struct {
    directory: []const u8,
    libraries: []const WindowsLibrary,
};

const windows_library_groups = [_]WindowsLibraryGroup{
    .{ .directory = "", .libraries = &.{.{ .release = "Siv3D.lib", .debug = "Siv3D_d.lib" }} },
    .{ .directory = "boost", .libraries = &.{.{
        .release = "libboost_filesystem-vc143-mt-s-x64-1_83.lib",
        .debug = "libboost_filesystem-vc143-mt-sgd-x64-1_83.lib",
    }} },
    .{ .directory = "curl", .libraries = &.{.{ .release = "libcurl.lib", .debug = "libcurl-d.lib" }} },
    .{ .directory = "freetype", .libraries = &.{.{ .release = "freetype.lib", .debug = "freetyped.lib" }} },
    .{ .directory = "glew", .libraries = &.{.{ .release = "glew32s.lib", .debug = "glew32sd.lib" }} },
    .{ .directory = "harfbuzz", .libraries = &.{.{ .release = "harfbuzz.lib", .debug = "harfbuzz_d.lib" }} },
    .{ .directory = "libgif", .libraries = &.{.{ .release = "libgif.lib", .debug = "libgif_d.lib" }} },
    .{ .directory = "libjpeg-turbo", .libraries = &.{.{
        .release = "turbojpeg-static.lib",
        .debug = "turbojpeg-static_d.lib",
    }} },
    .{ .directory = "libogg", .libraries = &.{.{ .release = "libogg.lib", .debug = "libogg_d.lib" }} },
    .{ .directory = "libpng", .libraries = &.{.{ .release = "libpng16.lib", .debug = "libpng16_d.lib" }} },
    .{ .directory = "libtiff", .libraries = &.{.{ .release = "tiff.lib", .debug = "tiffd.lib" }} },
    .{ .directory = "libvorbis", .libraries = &.{
        .{ .release = "libvorbis_static.lib", .debug = "libvorbis_static_d.lib" },
        .{ .release = "libvorbisfile_static.lib", .debug = "libvorbisfile_static_d.lib" },
    } },
    .{ .directory = "libwebp", .libraries = &.{.{ .release = "libwebp.lib", .debug = "libwebp_debug.lib" }} },
    .{ .directory = "Oniguruma", .libraries = &.{.{ .release = "Oniguruma.lib", .debug = "Oniguruma_d.lib" }} },
    .{ .directory = "opencv", .libraries = &.{
        .{ .release = "opencv_core451.lib", .debug = "opencv_core451d.lib" },
        .{ .release = "opencv_imgcodecs451.lib", .debug = "opencv_imgcodecs451d.lib" },
        .{ .release = "opencv_imgproc451.lib", .debug = "opencv_imgproc451d.lib" },
        .{ .release = "opencv_objdetect451.lib", .debug = "opencv_objdetect451d.lib" },
        .{ .release = "opencv_photo451.lib", .debug = "opencv_photo451d.lib" },
        .{ .release = "opencv_videoio451.lib", .debug = "opencv_videoio451d.lib" },
    } },
    .{ .directory = "opus", .libraries = &.{
        .{ .release = "opus.lib", .debug = "opus_d.lib" },
        .{ .release = "opusfile.lib", .debug = "opusfile_d.lib" },
    } },
    .{ .directory = "zlib", .libraries = &.{.{ .release = "zlib.lib", .debug = "zlibd.lib" }} },
};

const windows_debug_msvc_libraries = [_][]const u8{
    "libcpmtd.lib",
    "libcmtd.lib",
    "libvcruntimed.lib",
    "libconcrtd.lib",
    "oldnames.lib",
    "legacy_stdio_definitions.lib",
    "comsuppwd.lib",
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
    "crypt32",
    "d3d11",
    "d3dcompiler",
    "dinput8",
    "dwmapi",
    "dxgi",
    "dxguid",
    "gdi32",
    "imm32",
    "kernel32",
    "mf",
    "mfplat",
    "mfreadwrite",
    "mfuuid",
    "msimg32",
    "ntdll",
    "ole32",
    "oleaut32",
    "opengl32",
    "rpcrt4",
    "sapi",
    "secur32",
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
    link_libc: bool = true,
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
        .link_libc = options.link_libc,
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
    const runtime_root = "App";
    const use_debug_libraries = optimize == .Debug;

    const root_module = createCppModule(b, target, optimize, .{
        .flags = if (use_debug_libraries) &windows_debug_cxx_flags else &windows_release_cxx_flags,
        .link_libc = !use_debug_libraries,
        // Use the MSVC standard library selected by the target instead of Zig's libc++.
        .link_libcpp = null,
    });
    root_module.addSystemIncludePath(siv3d_sdk.path("include"));
    root_module.addSystemIncludePath(siv3d_sdk.path("include/ThirdParty"));

    const lib_root = "lib/Windows";
    for (windows_library_groups) |group| {
        const library_dir = if (group.directory.len == 0)
            lib_root
        else
            b.fmt("{s}/{s}", .{ lib_root, group.directory });
        root_module.addLibraryPath(siv3d_sdk.path(library_dir));
        for (group.libraries) |library| {
            const library_name = if (use_debug_libraries) library.debug else library.release;
            root_module.addObjectFile(siv3d_sdk.path(b.fmt("{s}/{s}", .{ library_dir, library_name })));
        }
    }
    if (use_debug_libraries) {
        addWindowsDebugRuntime(b, root_module, resolved);
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
    if (use_debug_libraries) {
        executable.entry = .{ .symbol_name = "WinMainCRTStartup" };
    }

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

fn addWindowsDebugRuntime(
    b: *std.Build,
    root_module: *std.Build.Module,
    target: std.Target,
) void {
    if (builtin.os.tag != .windows) {
        @panic("Windows Debug builds require MSVC and the Windows SDK on a Windows host");
    }

    var libc = std.zig.LibCInstallation.findNative(b.allocator, b.graph.io, .{
        .target = &target,
        .environ_map = &b.graph.environ_map,
    }) catch |err| {
        std.debug.panic("unable to locate the MSVC Debug runtime: {s}", .{@errorName(err)});
    };
    defer libc.deinit(b.allocator);

    const msvc_include_dir = libc.sys_include_dir orelse
        @panic("unable to locate the MSVC include directory");
    const windows_sdk_ucrt_include_dir = libc.include_dir orelse
        @panic("unable to locate the Windows SDK UCRT include directory");
    const windows_sdk_include_root = std.fs.path.dirname(windows_sdk_ucrt_include_dir) orelse
        @panic("invalid Windows SDK include directory");
    const msvc_lib_dir = libc.msvc_lib_dir orelse
        @panic("unable to locate the MSVC library directory");
    const windows_sdk_ucrt_lib_dir = libc.crt_dir orelse
        @panic("unable to locate the Windows SDK UCRT library directory");
    const windows_sdk_um_lib_dir = libc.kernel32_lib_dir orelse
        @panic("unable to locate the Windows SDK UM library directory");

    root_module.addSystemIncludePath(.{ .cwd_relative = msvc_include_dir });
    root_module.addSystemIncludePath(.{ .cwd_relative = windows_sdk_ucrt_include_dir });
    inline for (&.{ "shared", "um", "winrt", "cppwinrt" }) |directory| {
        root_module.addSystemIncludePath(.{
            .cwd_relative = b.pathJoin(&.{ windows_sdk_include_root, directory }),
        });
    }

    root_module.addLibraryPath(.{ .cwd_relative = msvc_lib_dir });
    root_module.addLibraryPath(.{ .cwd_relative = windows_sdk_ucrt_lib_dir });
    root_module.addLibraryPath(.{ .cwd_relative = windows_sdk_um_lib_dir });
    inline for (windows_debug_msvc_libraries) |library| {
        root_module.addObjectFile(.{
            .cwd_relative = b.pathJoin(&.{ msvc_lib_dir, library }),
        });
    }
    root_module.addObjectFile(.{
        .cwd_relative = b.pathJoin(&.{ windows_sdk_ucrt_lib_dir, "libucrtd.lib" }),
    });
}

fn makeWindowsResourceScript(b: *std.Build, runtime_app: std.Build.LazyPath) []const u8 {
    const runtime_app_path = runtime_app.getPath(b);
    var buffer = std.array_list.Managed(u8).init(b.allocator);
    buffer.appendSlice("#include <Siv3D/Windows/Resource.hpp>\n\n") catch @panic("OOM");
    for (windows_resource_dirs) |resource_dir| {
        appendWindowsResourceDir(b, &buffer, runtime_app_path, resource_dir);
    }

    const icon_path = b.pathJoin(&.{ runtime_app_path, "icon.ico" });
    std.Io.Dir.accessAbsolute(b.graph.io, icon_path, .{}) catch |err| {
        std.debug.panic("unable to access Siv3D icon '{s}': {s}", .{ icon_path, @errorName(err) });
    };
    buffer.appendSlice("DefineResource(100, ICON, icon.ico)\n") catch @panic("OOM");

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

        const relative_path = normalizeRcPath(b, b.pathJoin(&.{ resource_dir, entry.path }));
        // DefineResource stringizes the file path; quoting the identifier would become part of its name.
        buffer.print("DefineResource({s}, FILE, {s})\n", .{
            relative_path,
            relative_path,
        }) catch @panic("OOM");
    }
}

fn normalizeRcPath(b: *std.Build, path: []const u8) []const u8 {
    return std.mem.replaceOwned(u8, b.allocator, path, "\\", "/") catch @panic("OOM");
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
