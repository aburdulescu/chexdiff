const std = @import("std");
const builtin = @import("builtin");

const stdout = std.io.getStdOut().writer();

const usage =
    \\Usage: chexdiff [options] hex1 hex2
    \\
    \\Compare the two hex strings and print their differences.
    \\
    \\Options:
    \\    -h/--help    print this message
    \\    -v           print version
;

const version = "0.1";

pub fn main() !void {
    if (builtin.os.tag != .linux) {
        @compileError("requested OS is not supported!");
    }

    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa_instance.deinit();
    }
    const gpa = gpa_instance.allocator();

    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const args = try std.process.argsAlloc(arena);

    if (args.len == 1) {
        std.debug.print("{s}\n", .{usage});
        std.process.exit(1);
    }

    if (args.len >= 2) {
        if (std.mem.eql(u8, args[1], "-h") or std.mem.eql(u8, args[1], "--help")) {
            std.debug.print("{s}\n", .{usage});
            std.process.exit(1);
        }
        if (std.mem.eql(u8, args[1], "-v")) {
            try stdout.print("{s}\n", .{version});
            return;
        }
    }

    if (args.len != 3) {
        fatal("wrong number of args, need two: 1st and 2nd hex string", .{});
    }

    const first = args[1];
    if (first.len % 2 != 0) {
        fatal("'{s}' has invalid length", .{first});
    }

    const second = args[2];
    if (second.len % 2 != 0) {
        fatal("'{s}' has invalid length", .{second});
    }

    try stdout.print("hello\n", .{});
}

pub fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    std.process.exit(1);
}
