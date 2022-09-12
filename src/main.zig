const std = @import("std");
const builtin = @import("builtin");

const usage =
    \\Usage: chexdiff [options] hex1 hex2
    \\
    \\Compare the two hex strings and print their differences.
    \\
    \\Options:
    \\    -h/--help    print this message
    \\    -v           print version
;

const version = @embedFile("version.txt");

pub fn main() !void {
    if (builtin.os.tag != .linux) {
        @compileError("requested OS is not supported!");
    }

    const args = try std.process.argsAlloc(std.heap.c_allocator);

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
            try std.io.getStdOut().writer().print("{s}\n", .{version});
            std.process.exit(0);
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

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const w = bw.writer();

    try processHex(w, first, second);
    try processHex(w, second, first);

    try bw.flush();
}

pub fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    std.process.exit(1);
}

const RED = "\x1b[31;1m";
const RESET = "\x1b[0m";

fn isUpper(v: u8) bool {
    return v >= 'A' and v <= 'F';
}

test "isUpper" {
    const uppers = "ABCDEF";
    for (uppers) |c| {
        try std.testing.expect(isUpper(c));
    }
    const not_uppers = "abcdef0123456789xyz";
    for (not_uppers) |c| {
        try std.testing.expect(!isUpper(c));
    }
}

fn isCharEq(l: u8, r: u8) bool {
    const magic = 'a' - 'A';
    const ll = if (isUpper(l)) l + magic else l;
    const rr = if (isUpper(r)) r + magic else r;
    return ll == rr;
}

test "isCharEq" {
    try std.testing.expect(isCharEq('A', 'a'));
    try std.testing.expect(!isCharEq('A', 'b'));
}

fn isHexDigitEq(l: []const u8, r: []const u8) bool {
    return isCharEq(l[0], r[0]) and isCharEq(l[1], r[1]);
}

test "isHexDigitEq" {
    try std.testing.expect(isHexDigitEq("AA", "AA"));
    try std.testing.expect(isHexDigitEq("AA", "aa"));
    try std.testing.expect(!isHexDigitEq("AA", "BB"));
    try std.testing.expect(!isHexDigitEq("AA", "bb"));
}

fn processHex(w: anytype, self: []const u8, other: []const u8) !void {
    const cmn_len = if (self.len < other.len) self.len else other.len;
    var i: usize = 0;
    while (i < cmn_len) : (i += 2) {
        if (isHexDigitEq(self[i .. i + 2], other[i .. i + 2])) {
            try std.fmt.format(w, "{s}", .{self[i .. i + 2]});
        } else {
            try std.fmt.format(w, "{s}{s}{s}", .{ RED, self[i .. i + 2], RESET });
        }
    }
    if (self.len > other.len) {
        try std.fmt.format(w, "{s}{s}{s}", .{ RED, self[other.len..], RESET });
    }
    try std.fmt.format(w, "\n", .{});
}

test "processHexStringsEqual" {
    const expected = "ffff0102";

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try processHex(w, expected, expected);

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, result, expected);
}

test "processHexStringsNotEqual" {
    const l = "ffff";
    const r = "fff0";

    const expected = "ff" ++ RED ++ "ff" ++ RESET;

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try processHex(w, l, r);

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, result, expected);
}

test "processHexMixedCase" {
    const l = "FFaa";
    const r = "ffAA";

    const expected = l;

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try processHex(w, l, r);

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, result, expected);
}
