const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    b.setPreferredReleaseMode(.ReleaseSmall);

    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const single_threaded = b.option(bool, "single-threaded", "Build artifacts that run in single threaded mode") orelse true;
    const strip = b.option(bool, "strip", "Omit debug information") orelse true;

    const exe = b.addExecutable("chexdiff", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.strip = strip;
    exe.single_threaded = single_threaded;
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
