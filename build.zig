const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const strip = b.option(bool, "strip", "Strip the binary") orelse switch (optimize) {
        .Debug, .ReleaseSafe => false,
        .ReleaseFast, .ReleaseSmall => true,
    };

    const exe = b.addExecutable(.{
        .name = "chexdiff",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.strip = strip;
    exe.single_threaded = true;

    b.installArtifact(exe);

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe_tests.linkLibC();

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
