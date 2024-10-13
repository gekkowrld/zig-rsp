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

    var argument = std.ArrayList(u8).init(allocator);
    var inside_block: bool = false;

    // Read the file "line by line"
    // Instead of relyiing on the zig readUntilDelimiterOrEof(), I'll just go through the buffer byte by byte.
    for (fp) |fb| {
        // Should check if this appears in a line which was not at the end
        if (!inside_block and fb == '{') {
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

    return try arguments.toOwnedSlice();
}
