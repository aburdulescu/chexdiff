const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    b.setPreferredReleaseMode(.ReleaseSafe);

    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const strip = b.option(bool, "strip", "Omit debug information") orelse false;

    const exe = b.addExecutable("chexdiff", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.strip = strip;
    exe.single_threaded = true;
    exe.install();

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
