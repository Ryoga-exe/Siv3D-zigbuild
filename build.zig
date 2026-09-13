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

const linux_pkg_config_libraries = [_][]const u8{
    "alsa",
    "libavcodec",
    "libavformat",
    "libavutil",
    "libcurl",
    "freetype2",
    "gl",
    "glib-2.0",
    "gtk+-3.0",
    "harfbuzz",
    "libmpg123",
    "ogg",
    "opus",
    "opusfile",
    "libpng",
    "soundtouch",
    "libswresample",
    "libswscale",
    "libtiff-4",
    "libturbojpeg",
    "uuid",
    "vorbis",
    "vorbisenc",
    "vorbisfile",
    "libwebp",
    "x11",
    "glu",
    "xft",
    "zlib",
};

const linux_system_libraries = [_][]const u8{
    "dl",
    "gif",
    "jpeg",
    "m",
    "pthread",
    "rt",
};

const linux_sdk_libraries = [_][]const u8{
    "lib/libSiv3D.a",
    "lib/libopencv_world.a",
    "lib/opencv4/3rdparty/libade.a",
    "lib/opencv4/3rdparty/libquirc.a",
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
    release_path: []const u8,
    debug_path: []const u8,
};

const windows_libraries = [_]WindowsLibrary{
    .{ .release_path = "lib/Windows/Siv3D.lib", .debug_path = "lib/Windows/Siv3D_d.lib" },
    .{ .release_path = "lib/Windows/boost/libboost_filesystem-vc143-mt-s-x64-1_83.lib", .debug_path = "lib/Windows/boost/libboost_filesystem-vc143-mt-sgd-x64-1_83.lib" },
    .{ .release_path = "lib/Windows/curl/libcurl.lib", .debug_path = "lib/Windows/curl/libcurl-d.lib" },
    .{ .release_path = "lib/Windows/freetype/freetype.lib", .debug_path = "lib/Windows/freetype/freetyped.lib" },
    .{ .release_path = "lib/Windows/glew/glew32s.lib", .debug_path = "lib/Windows/glew/glew32sd.lib" },
    .{ .release_path = "lib/Windows/harfbuzz/harfbuzz.lib", .debug_path = "lib/Windows/harfbuzz/harfbuzz_d.lib" },
    .{ .release_path = "lib/Windows/libgif/libgif.lib", .debug_path = "lib/Windows/libgif/libgif_d.lib" },
    .{ .release_path = "lib/Windows/libjpeg-turbo/turbojpeg-static.lib", .debug_path = "lib/Windows/libjpeg-turbo/turbojpeg-static_d.lib" },
    .{ .release_path = "lib/Windows/libogg/libogg.lib", .debug_path = "lib/Windows/libogg/libogg_d.lib" },
    .{ .release_path = "lib/Windows/libpng/libpng16.lib", .debug_path = "lib/Windows/libpng/libpng16_d.lib" },
    .{ .release_path = "lib/Windows/libtiff/tiff.lib", .debug_path = "lib/Windows/libtiff/tiffd.lib" },
    .{ .release_path = "lib/Windows/libvorbis/libvorbis_static.lib", .debug_path = "lib/Windows/libvorbis/libvorbis_static_d.lib" },
    .{ .release_path = "lib/Windows/libvorbis/libvorbisfile_static.lib", .debug_path = "lib/Windows/libvorbis/libvorbisfile_static_d.lib" },
    .{ .release_path = "lib/Windows/libwebp/libwebp.lib", .debug_path = "lib/Windows/libwebp/libwebp_debug.lib" },
    .{ .release_path = "lib/Windows/Oniguruma/Oniguruma.lib", .debug_path = "lib/Windows/Oniguruma/Oniguruma_d.lib" },
    .{ .release_path = "lib/Windows/opencv/opencv_core451.lib", .debug_path = "lib/Windows/opencv/opencv_core451d.lib" },
    .{ .release_path = "lib/Windows/opencv/opencv_imgcodecs451.lib", .debug_path = "lib/Windows/opencv/opencv_imgcodecs451d.lib" },
    .{ .release_path = "lib/Windows/opencv/opencv_imgproc451.lib", .debug_path = "lib/Windows/opencv/opencv_imgproc451d.lib" },
    .{ .release_path = "lib/Windows/opencv/opencv_objdetect451.lib", .debug_path = "lib/Windows/opencv/opencv_objdetect451d.lib" },
    .{ .release_path = "lib/Windows/opencv/opencv_photo451.lib", .debug_path = "lib/Windows/opencv/opencv_photo451d.lib" },
    .{ .release_path = "lib/Windows/opencv/opencv_videoio451.lib", .debug_path = "lib/Windows/opencv/opencv_videoio451d.lib" },
    .{ .release_path = "lib/Windows/opus/opus.lib", .debug_path = "lib/Windows/opus/opus_d.lib" },
    .{ .release_path = "lib/Windows/opus/opusfile.lib", .debug_path = "lib/Windows/opus/opusfile_d.lib" },
    .{ .release_path = "lib/Windows/zlib/zlib.lib", .debug_path = "lib/Windows/zlib/zlibd.lib" },
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

    switch (target.result.os.tag) {
        .macos => buildMacOS(b, target, optimize),
        .linux => buildLinux(b, target, optimize),
        .windows => buildWindows(b, target, optimize),
        else => @panic("this PoC currently supports only x86_64-macos, x86_64-linux-gnu, and x86_64-windows-msvc"),
    }
}

fn defaultTarget() std.Target.Query {
    return switch (builtin.os.tag) {
        .windows => .{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .msvc,
        },
        .macos => .{
            .cpu_arch = .x86_64,
            .os_tag = .macos,
            .os_version_min = .{ .semver = minimum_macos_version },
        },
        // Linux uses the native target because its libc, libstdc++, and pkg-config
        // dependencies all come from the host system.
        .linux => .{},
        else => .{},
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
) void {
    const resolved = target.result;
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
        root_module.addObjectFile(siv3d_sdk.path("lib/macOS/" ++ library));
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

fn buildLinux(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const resolved = target.result;
    if (resolved.cpu.arch != .x86_64 or resolved.abi != .gnu) {
        @panic("Linux support currently requires x86_64-linux-gnu");
    }
    if (builtin.os.tag != .linux or builtin.cpu.arch != .x86_64) {
        @panic("Linux builds currently require an x86_64 Linux host");
    }

    const siv3d_sdk = b.lazyDependency("siv3d_linux", .{}) orelse return;
    const root_module = createCppModule(b, target, optimize, .{
        .flags = &cxx_flags,
        .link_libcpp = false,
    });
    root_module.addSystemIncludePath(siv3d_sdk.path("include/Siv3D"));
    root_module.addSystemIncludePath(siv3d_sdk.path("include/Siv3D/ThirdParty"));
    root_module.addSystemIncludePath(siv3d_sdk.path("include/opencv4"));
    inline for (linux_sdk_libraries) |library| {
        root_module.addObjectFile(siv3d_sdk.path(library));
    }

    addLinuxSystemCxxRuntime(b, root_module);
    inline for (linux_pkg_config_libraries) |library| {
        root_module.linkSystemLibrary(library, .{ .use_pkg_config = .force });
    }
    inline for (linux_system_libraries) |library| {
        root_module.linkSystemLibrary(library, .{ .use_pkg_config = .no });
    }

    const executable = b.addExecutable(.{
        .name = app_name,
        .root_module = root_module,
        .version = app_version,
    });
    // GCC installations may expose libstdc++.so as a linker script.
    executable.allow_so_scripts = true;

    const install_executable = b.addInstallArtifact(executable, .{});
    const install_engine = b.addInstallDirectory(.{
        .source_dir = siv3d_sdk.path("share/Siv3D/resources/engine"),
        .install_dir = .bin,
        .install_subdir = "resources/engine",
    });

    const install_step = b.getInstallStep();
    install_step.dependOn(&install_executable.step);
    install_step.dependOn(&install_engine.step);

    const run = b.addSystemCommand(&.{b.getInstallPath(.bin, app_name)});
    run.step.dependOn(install_step);
    const run_step = b.step("run", "Build and run the executable");
    run_step.dependOn(&run.step);
}

fn addLinuxSystemCxxRuntime(b: *std.Build, root_module: *std.Build.Module) void {
    const compiler = if (b.graph.environ_map.get("CXX")) |cxx|
        b.findProgram(&.{cxx}, &.{}) catch
            std.debug.panic("unable to find the C++ compiler specified by CXX: '{s}'", .{cxx})
    else
        b.findProgram(&.{ "c++", "g++" }, &.{}) catch
            @panic("unable to find a system C++ compiler; install GCC or set CXX");

    var probe_environment = b.graph.environ_map.clone(b.allocator) catch @panic("OOM");
    defer probe_environment.deinit();
    probe_environment.put("LC_ALL", "C") catch @panic("OOM");

    const include_probe = std.process.run(b.allocator, b.graph.io, .{
        .argv = &.{ compiler, "-E", "-x", "c++", "-v", "/dev/null" },
        .environ_map = &probe_environment,
    }) catch |err| {
        std.debug.panic("unable to query system C++ include paths: {s}", .{@errorName(err)});
    };
    defer b.allocator.free(include_probe.stdout);
    defer b.allocator.free(include_probe.stderr);
    requireSuccessfulCompilerProbe(compiler, include_probe.term, include_probe.stderr);

    var found_cxx_include = false;
    var in_include_list = false;
    var lines = std.mem.splitScalar(u8, include_probe.stderr, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (std.mem.eql(u8, line, "#include <...> search starts here:")) {
            in_include_list = true;
            continue;
        }
        if (std.mem.eql(u8, line, "End of search list.")) break;
        if (!in_include_list) continue;

        if (!std.fs.path.isAbsolute(line)) {
            std.debug.panic("system C++ compiler returned a non-absolute include path: '{s}'", .{line});
        }
        // Preserve the compiler's complete search order. libstdc++ headers use
        // #include_next to reach system C headers such as math.h.
        root_module.addSystemIncludePath(.{ .cwd_relative = line });
        if (std.mem.indexOf(u8, line, "/c++/") != null) {
            found_cxx_include = true;
        }
    }
    if (!found_cxx_include) {
        std.debug.panic("unable to find libstdc++ include paths reported by '{s}'", .{compiler});
    }

    const library_probe = std.process.run(b.allocator, b.graph.io, .{
        .argv = &.{ compiler, "-print-file-name=libstdc++.so" },
        .environ_map = &probe_environment,
    }) catch |err| {
        std.debug.panic("unable to query the system libstdc++ library: {s}", .{@errorName(err)});
    };
    defer b.allocator.free(library_probe.stdout);
    defer b.allocator.free(library_probe.stderr);
    requireSuccessfulCompilerProbe(compiler, library_probe.term, library_probe.stderr);

    const libstdcxx_path = std.mem.trim(u8, library_probe.stdout, " \t\r\n");
    if (!std.fs.path.isAbsolute(libstdcxx_path)) {
        std.debug.panic("'{s}' did not report an absolute path for libstdc++.so", .{compiler});
    }
    root_module.addObjectFile(.{ .cwd_relative = libstdcxx_path });
}

fn requireSuccessfulCompilerProbe(
    compiler: []const u8,
    term: std.process.Child.Term,
    stderr: []const u8,
) void {
    switch (term) {
        .exited => |code| if (code == 0) return,
        else => {},
    }
    std.debug.panic("system C++ compiler probe failed for '{s}':\n{s}", .{ compiler, stderr });
}

fn buildWindows(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const resolved = target.result;
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

    for (windows_libraries) |library| {
        const library_path = if (use_debug_libraries) library.debug_path else library.release_path;
        root_module.addObjectFile(siv3d_sdk.path(library_path));
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
        .source_dir = siv3d_runtime.path(runtime_root ++ "/dll"),
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
