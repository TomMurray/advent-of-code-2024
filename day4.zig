const std = @import("std");

pub const std_options: std.Options = .{ .log_level = .debug };

const Day4Error = error{
    NotEnoughArgs,
    InvalidPart,
};

const Coord = struct { x: i32, y: i32 };

fn flatten_coord(coord: Coord, width: usize) usize {
    return @as(usize, @intCast(coord.y * @as(i32, @intCast(width)) + coord.x));
}

fn check_needle(needle: []const u8, haystack: []const u8, row_len: usize, coord: Coord, offset: Coord) bool {
    if (needle.len == 0)
        return true;

    if (coord.x < 0 or coord.x >= row_len or
        coord.y < 0 or coord.y >= haystack.len / row_len)
        return false;

    if (haystack[flatten_coord(coord, row_len)] != needle[0])
        return false;

    return check_needle(needle[1..], haystack, row_len, .{ .x = coord.x + offset.x, .y = coord.y + offset.y }, offset);
}

fn needle_count(needle: []const u8, haystack: []const u8, row_len: usize, coord: Coord) usize {
    var count: usize = 0;
    for ([_]Coord{
        .{ .x = 1, .y = 0 },
        .{ .x = 1, .y = 1 },
        .{ .x = 0, .y = 1 },
        .{ .x = -1, .y = 1 },
        .{ .x = -1, .y = 0 },
        .{ .x = -1, .y = -1 },
        .{ .x = 0, .y = -1 },
        .{ .x = 1, .y = -1 },
    }) |offset| {
        if (check_needle(needle, haystack, row_len, coord, offset)) {
            count += 1;
        }
    }
    return count;
}

fn is_mas_cross(haystack: []const u8, w: usize, c: Coord) bool {
    // Check we aren't too close to the edges
    std.debug.assert(!(c.x <= 0 or c.x >= w - 1 or c.y <= 0 or c.y >= (haystack.len / w) - 1));

    if (haystack[flatten_coord(c, w)] != 'A')
        return false;

    // Check cross
    const ul = haystack[flatten_coord(.{ .x = c.x - 1, .y = c.y - 1 }, w)];
    const ur = haystack[flatten_coord(.{ .x = c.x + 1, .y = c.y - 1 }, w)];
    const ll = haystack[flatten_coord(.{ .x = c.x - 1, .y = c.y + 1 }, w)];
    const lr = haystack[flatten_coord(.{ .x = c.x + 1, .y = c.y + 1 }, w)];

    return ((ul == 'M' and lr == 'S') or
        (ul == 'S' and lr == 'M')) and ((ll == 'M' and ur == 'S') or
        (ll == 'S' and ur == 'M'));
}

pub fn main() !void {
    std.log.info("Hello world!", .{});

    const argv = std.os.argv;
    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day4Error.NotEnoughArgs;
    }
    const file_path = std.mem.span(argv[1]);
    const part = try std.fmt.parseInt(i32, std.mem.span(argv[2]), 10);

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf: [1024]u8 = undefined;
    var arr = std.ArrayList(u8).init(std.heap.page_allocator);
    defer arr.deinit();

    var width: ?usize = null;
    while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.log.debug("Input row: {s}", .{line});
        std.debug.assert(line.len != 0);
        if (width) |w| {
            std.debug.assert(line.len == w);
        } else {
            width = line.len;
        }
        try arr.appendSlice(line);
    }

    std.log.debug("Input data is {d} elements, row length is {d}", .{ arr.items.len, width.? });

    switch (part) {
        1 => {
            var count: usize = 0;
            for (0..(arr.items.len / width.?)) |y| {
                for (0..width.?) |x| {
                    count += needle_count("XMAS", arr.items, width.?, .{ .x = @intCast(x), .y = @intCast(y) });
                }
            }
            std.log.info("Total found count of 'XMAS' was {d}", .{count});
        },
        2 => {
            var count: usize = 0;
            for (1..(arr.items.len / width.? - 1)) |y| {
                for (1..(width.? - 1)) |x| {
                    count += if (is_mas_cross(arr.items, width.?, .{ .x = @intCast(x), .y = @intCast(y) })) 1 else 0;
                }
            }
            std.log.info("Total 'MAS' crosses was {d}", .{count});
        },
        else => return Day4Error.InvalidPart,
    }
}
