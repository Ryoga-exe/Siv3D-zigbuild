const std = @import("std");

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

const siv3d_libraries = [_][]const u8{
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

const system_libraries = [_][]const u8{
    "curl",
    "objc",
};

const system_frameworks = [_][]const u8{
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

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .macos,
            .os_version_min = .{ .semver = minimum_macos_version },
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const resolved = target.result;
    if (resolved.os.tag != .macos or resolved.cpu.arch != .x86_64) {
        @panic("this PoC currently supports only x86_64-macos");
    }

    const siv3d_sdk = b.lazyDependency("siv3d_macos", .{}) orelse return;
    const macos_sdk = b.sysroot orelse
        std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &resolved) orelse
        @panic("unable to locate the macOS SDK; install Xcode Command Line Tools");
    b.sysroot = macos_sdk;
    const macos_sdk_root: std.Build.LazyPath = .{ .cwd_relative = macos_sdk };

    const root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    root_module.addCSourceFiles(.{
        .files = &cpp_sources,
        .flags = &cxx_flags,
        .language = .cpp,
    });
    root_module.addSystemIncludePath(siv3d_sdk.path("include"));
    root_module.addSystemIncludePath(siv3d_sdk.path("include/ThirdParty"));
    // Zig resolves the absolute library search path inside --sysroot on Darwin.
    root_module.addLibraryPath(.{ .cwd_relative = "/usr/lib" });
    root_module.addFrameworkPath(macos_sdk_root.path(b, "System/Library/Frameworks"));

    inline for (siv3d_libraries) |library| {
        root_module.addObjectFile(siv3d_sdk.path(b.fmt("lib/macOS/{s}", .{library})));
    }
    inline for (system_libraries) |library| {
        root_module.linkSystemLibrary(library, .{});
    }
    inline for (system_frameworks) |framework| {
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
