const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const fs = std.fs;

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const opts = try parseResponseFile(arena.allocator(), "test.rsp");

    for (opts) |opt| {
        std.debug.print("~{s}@\n", .{opt});
    }
}

/// Parse the response file
/// If a file is not found, the error will be silently ignored with the file being returned as the argument instead.
/// Each line will be treated as an argument with `{}` being treated as a block
pub fn parseResponseFile(allocator: mem.Allocator, response_file: []const u8) ![][]const u8 {
    var arguments = std.ArrayList([]const u8).init(allocator);

    // open the file with the arena provided
    const fp = fs.cwd().readFileAlloc(allocator, response_file, std.zig.max_src_size) catch |err| switch (err) {
        error.FileNotFound => {
            try arguments.append(response_file);
            return try arguments.toOwnedSlice();
        },
        else => return err,
    };
    errdefer allocator.free(fp);

    arguments = try parseResponseContent(allocator, fp, &arguments);

    return try arguments.toOwnedSlice();
}

pub fn parseResponseContent(allocator: mem.Allocator, content: []u8, arguments: *std.ArrayList([]const u8)) !std.ArrayList([]const u8) {
    var argument = std.ArrayList(u8).init(allocator);
    var inside_block: bool = false;

    // Read the file "line by line"
    // Instead of relyiing on the zig readUntilDelimiterOrEof(), I'll just go through the buffer byte by byte.
    for (content) |fb| {
        if (!inside_block and fb == '{') {
            // Check if there is the value here is something instead of nothing
            const val = try argument.toOwnedSlice();
            const value = mem.trim(u8, val, "\x20\x09\x0C\x0A\x0D\x0B");

            // Skip if this may inside a comment
            if (value.len > 0 and mem.startsWith(u8, value, "#")) {
                // Readd everything back and continue
                for (value) |av| {
                    try argument.append(av);
                }
                try argument.append(fb);
                continue;
            }

            if (value.len > 0) {
                // An error since this means something was already being collected.
                return error.TooManyOptions;
            }

            inside_block = true;
            continue;
        }

        if (inside_block and fb == '}') {
            inside_block = false;
            try arguments.append(try argument.toOwnedSlice());
            continue;
        }

        if (!inside_block and (fb == '\n' or fb == '\r')) {
            const val = try argument.toOwnedSlice();
            const value = mem.trim(u8, val, "\x20\x09\x0C\x0A\x0D\x0B");
            if (value.len <= 0 or mem.startsWith(u8, value, "#"))
                continue;

            try arguments.append(value);
            continue;
        }

        try argument.append(fb);
    }

    return arguments.*;
}

test "passing non_existent response file" {
    const expect = std.testing.expect;

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const nefile = "a.totally'non{existennt}+file-being_used";
    const args = try parseResponseFile(arena.allocator(), nefile);

    try expect(args.len == 1);
    try expect(mem.eql(u8, args[0], nefile));
}

test "passing available file" {
    const expect = std.testing.expect;

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const file1 = "test/file1.rsp";
    const args1 = try parseResponseFile(arena.allocator(), file1);

    try expect(args1.len == 0);

    const file2 = "test/file2.rsp";
    const args2 = try parseResponseFile(arena.allocator(), file2);

    try expect(args2.len == 1);
    try expect(mem.eql(u8, args2[0], "-W0"));

    const file3 = "test/file3.rsp";
    const args3 = try parseResponseFile(arena.allocator(), file3);

    try expect(args3.len == 5);
}

test "parseResponseContent" {
    const expect = std.testing.expect;

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    var arguments = std.ArrayList([]const u8).init(arena.allocator());

    // Empty case
    arguments = try parseResponseContent(arena.allocator(), "", &arguments);

    const varg = try arguments.toOwnedSlice();
    try expect(varg.len == 0);
}
