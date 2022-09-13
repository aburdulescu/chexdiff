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

    try processStrings(w, first, second);

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

fn processStrings(w: anytype, first: []const u8, second: []const u8) !void {
    const min_len = std.math.min(first.len, second.len);
    var i: usize = 0;
    while (i < min_len) : (i += 2) {
        const l = first[i .. i + 2];
        const r = second[i .. i + 2];
        if (isHexDigitEq(l, r)) {
            try std.fmt.format(w, "{s} {s}\n", .{ l, r });
        } else {
            try std.fmt.format(w, "{s}{s} {s}{s}\n", .{ RED, l, r, RESET });
        }
    }
    if (first.len == second.len) return;
    var extra: []const u8 = undefined;
    var padding: []const u8 = undefined;
    if (first.len > second.len) {
        extra = first[i..];
        padding = "";
    } else {
        extra = second[i..];
        padding = "   ";
    }
    var j: usize = 0;
    while (j < extra.len) : (j += 2) {
        try std.fmt.format(w, "{s}{s}{s}{s}\n", .{ RED, padding, extra[j .. j + 2], RESET });
    }
}

test "processStringsEqual" {
    const input = "ffff0102";

    const expected = "ff ff\nff ff\n01 01\n02 02";

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try processStrings(w, input, input);

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, expected, result);
}

test "processStringsNotEqual" {
    const l = "ffff";
    const r = "fff0";

    const expected = "ff ff\n" ++ RED ++ "ff f0" ++ RESET;

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try processStrings(w, l, r);

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, expected, result);
}

test "processMixedCase" {
    const l = "FFaa";
    const r = "ffAA";

    const expected = "FF ff\naa AA";

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try processStrings(w, l, r);

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, expected, result);
}

test "processStringsFirstIsBigger" {
    const l = "ffff00";
    const r = "ffff";

    const expected = "ff ff\nff ff\n" ++ RED ++ "00" ++ RESET;

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try processStrings(w, l, r);

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, expected, result);
}

test "processStringsSecondIsBigger" {
    const l = "ffff";
    const r = "ffff00";

    const expected = "ff ff\nff ff\n" ++ RED ++ "   00" ++ RESET;

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try processStrings(w, l, r);

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, expected, result);
}
