const std = @import("std");
const util = @import("util.zig");

const Day6Error = error{
    NotEnoughArgs,
    InvalidPart,
};

const Dir = enum {
    Up,
    Right,
    Down,
    Left,
    Count,
    pub fn next(self: *Dir) Dir {
        return @enumFromInt((@intFromEnum(self.*) + 1) % @intFromEnum(Dir.Count));
    }

    pub fn get_stride(self: *Dir, row_stride: i32) i32 {
        return switch (self.*) {
            Dir.Up => -row_stride,
            Dir.Right => 1,
            Dir.Down => row_stride,
            Dir.Left => -1,
            else => unreachable,
        };
    }
};

pub fn main() !void {
    const argv = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, argv);

    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day6Error.NotEnoughArgs;
    }
    const file_path = argv[1];
    const part = try std.fmt.parseInt(i32, argv[2], 10);

    const file = try std.fs.cwd().openFile(file_path, .{});

    var arr = try file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(usize));

    const row_stride: i32 = for (arr, 0..) |c, i| {
        if (c == '\n') {
            break @intCast(i + 1);
        }
    } else unreachable;

    // Find the starting point
    var pos = for (arr, 0..) |c, i| {
        if (c == '^') {
            break i;
        }
    } else unreachable;

    var dir = Dir.Up;

    switch (part) {
        1 => {
            var count: usize = 0;
            while (true) {
                if (arr[pos] != 'X') {
                    count += 1;
                    arr[pos] = 'X';
                }

                const stride = dir.get_stride(row_stride);
                const next_pos = @as(i32, @intCast(pos)) + stride;

                if (next_pos < 0 or next_pos >= arr.len)
                    break;

                const next_idx: usize = @intCast(next_pos);

                if (arr[next_idx] == '\n' or arr[next_idx] == '\r')
                    break;

                if (arr[next_idx] == '#') {
                    dir = dir.next();
                } else {
                    pos = next_idx;
                }
            }

            std.log.info("Total unique position count was {d}", .{count});
        },
        else => return Day6Error.InvalidPart,
    }
}
