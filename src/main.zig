const std = @import("std");
const builtin = @import("builtin");

const usage =
    \\Usage: chexdiff [options] input1 input2
    \\
    \\Compare the two given inputs as hex and print their differences, if any.
    \\
    \\Options:
    \\    -h    print this message and exit
    \\    -v    print version and exit
    \\    -i    case insensitive comparison
    \\    -f    treat inputs as files and compare their contents
    \\    -x    if -f is active, convert file contents to hex before comparing them
;

const version = @embedFile("version.txt");

pub fn main() !void {
    if (builtin.os.tag != .linux) {
        @compileError("requested OS is not supported!");
    }

    const allocator = std.heap.c_allocator;

    const args = try std.process.argsAlloc(allocator);

    if (args.len == 1) {
        std.debug.print("{s}\n", .{usage});
        std.process.exit(1);
    }

    if (args.len >= 2) {
        if (std.mem.eql(u8, args[1], "-h")) {
            std.debug.print("{s}\n", .{usage});
            std.process.exit(1);
        }
        if (std.mem.eql(u8, args[1], "-v")) {
            try std.io.getStdOut().writer().print("{s}\n", .{version});
            std.process.exit(0);
        }
    }

    var flag_ignore_case = false;
    var flag_as_files = false;
    var flag_convert_to_hex = false;

    var i: usize = 1;
    var n: usize = args.len;

    while (args[i][0] == '-') {
        if (std.mem.eql(u8, args[i], "-i")) {
            flag_ignore_case = true;
        }
        if (std.mem.eql(u8, args[i], "-f")) {
            flag_as_files = true;
        }
        if (std.mem.eql(u8, args[i], "-x")) {
            flag_convert_to_hex = true;
        }
        i += 1;
        n -= 1;
    }

    if (n != 3) {
        fatal("wrong number of args, need two: 1st and 2nd hex string/file", .{});
    }

    var first: []const u8 = undefined;
    if (flag_as_files) {
        const data = readFile(allocator, args[i]) catch |err| {
            fatal("could not read file '{s}': {}", .{ args[i], err });
        };
        if (!flag_convert_to_hex) {
            first = data;
            if (first[first.len - 1] == '\n') {
                first = first[0 .. first.len - 1];
            }
        } else {
            var buf = try allocator.alloc(u8, data.len * 2);
            first = try std.fmt.bufPrint(buf, "{}", .{std.fmt.fmtSliceHexLower(data)});
        }
    } else {
        first = args[i];
    }
    if (first.len % 2 != 0) {
        if (flag_as_files) {
            fatal("content of file '{s}' has invalid length", .{args[i]});
        } else {
            fatal("{s} has invalid length", .{first});
        }
    }
    if (!isHex(first)) {
        if (flag_as_files) {
            fatal("content of file '{s}' is not a hex string", .{args[i]});
        } else {
            fatal("{s} is not a hex string", .{first});
        }
    }
    i += 1;

    var second: []const u8 = undefined;
    if (flag_as_files) {
        const data = readFile(allocator, args[i]) catch |err| {
            fatal("could not read file '{s}': {}", .{ args[i], err });
        };
        if (!flag_convert_to_hex) {
            second = data;
            if (second[second.len - 1] == '\n') {
                second = second[0 .. second.len - 1];
            }
        } else {
            var buf = try allocator.alloc(u8, data.len * 2);
            second = try std.fmt.bufPrint(buf, "{}", .{std.fmt.fmtSliceHexLower(data)});
        }
    } else {
        second = args[i];
    }
    if (second.len % 2 != 0) {
        if (flag_as_files) {
            fatal("content of file '{s}' has invalid length", .{args[i]});
        } else {
            fatal("{s} has invalid length", .{second});
        }
    }
    if (!isHex(second)) {
        if (flag_as_files) {
            fatal("content of file '{s}' is not a hex string", .{args[i]});
        } else {
            fatal("{s} is not a hex string", .{second});
        }
    }
    i += 1;

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const w = bw.writer();

    const result = try processStrings(w, first, second, flag_ignore_case);

    if (!result) {
        try bw.flush();
        std.process.exit(1);
    }
}

fn isHex(in: []const u8) bool {
    for (in) |c| {
        if (!isHexDigit(c)) return false;
    }
    return true;
}

fn readFile(all: std.mem.Allocator, path: []const u8) ![]const u8 {
    const f = try std.fs.cwd().openFile(path, std.fs.File.OpenFlags{});
    defer f.close();
    const st = try f.stat();
    const content = try f.reader().readAllAlloc(all, st.size);
    return content;
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

fn isHexDigit(v: u8) bool {
    return (v >= '0' and v <= '9') or (v >= 'a' and v <= 'f') or (v >= 'A' and v <= 'F');
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

fn isCharEqual(l: u8, r: u8) bool {
    return l == r;
}

fn isCharEqualIgnCase(l: u8, r: u8) bool {
    const magic = 'a' - 'A';
    const ll = if (isUpper(l)) l + magic else l;
    const rr = if (isUpper(r)) r + magic else r;
    return ll == rr;
}

test "isCharEqual" {
    try std.testing.expect(!isCharEqual('A', 'a'));
    try std.testing.expect(!isCharEqual('A', 'b'));
    try std.testing.expect(isCharEqual('a', 'a'));
    try std.testing.expect(isCharEqual('A', 'A'));
}

test "isCharEqualIgnCase" {
    try std.testing.expect(isCharEqualIgnCase('A', 'a'));
    try std.testing.expect(!isCharEqualIgnCase('A', 'b'));
    try std.testing.expect(isCharEqualIgnCase('A', 'A'));
    try std.testing.expect(!isCharEqualIgnCase('A', 'B'));
}

fn isHexDigitEqual(l: []const u8, r: []const u8, ignore_case: bool) bool {
    if (ignore_case) {
        return isCharEqualIgnCase(l[0], r[0]) and isCharEqualIgnCase(l[1], r[1]);
    } else {
        return isCharEqual(l[0], r[0]) and isCharEqual(l[1], r[1]);
    }
}

test "isHexDigitEq" {
    try std.testing.expect(isHexDigitEqual("AA", "AA", false));
    try std.testing.expect(!isHexDigitEqual("AA", "aa", false));
    try std.testing.expect(!isHexDigitEqual("AA", "BB", false));
    try std.testing.expect(!isHexDigitEqual("AA", "bb", false));
    try std.testing.expect(isHexDigitEqual("AA", "AA", true));
    try std.testing.expect(isHexDigitEqual("AA", "aa", true));
    try std.testing.expect(!isHexDigitEqual("AA", "BB", true));
    try std.testing.expect(!isHexDigitEqual("AA", "bb", true));
}

fn processStrings(w: anytype, first: []const u8, second: []const u8, ignore_case: bool) !bool {
    const min_len = std.math.min(first.len, second.len);
    var result = true;
    var i: usize = 0;
    while (i < min_len) : (i += 2) {
        const l = first[i .. i + 2];
        const r = second[i .. i + 2];
        if (isHexDigitEqual(l, r, ignore_case)) {
            try std.fmt.format(w, "{s} {s}\n", .{ l, r });
        } else {
            try std.fmt.format(w, "{s}{s} {s}{s}\n", .{ RED, l, r, RESET });
            result = false;
        }
    }
    if (first.len == second.len) return result;
    result = false;
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
    return result;
}

test "processStringsEqual" {
    const input = "ffff0102";

    const expected = "ff ff\nff ff\n01 01\n02 02";

    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    try std.testing.expect(try processStrings(w, input, input, true));

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

    try std.testing.expect(!try processStrings(w, l, r, false));

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

    try std.testing.expect(try processStrings(w, l, r, true));

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

    try std.testing.expect(!try processStrings(w, l, r, false));

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

    try std.testing.expect(!try processStrings(w, l, r, true));

    const result = buf[0 .. fbs.pos - 1];

    try std.testing.expectEqualSlices(u8, expected, result);
}
