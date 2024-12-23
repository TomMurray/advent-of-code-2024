const std = @import("std");
const Coord = @import("coord.zig").Coord;

pub const std_options: std.Options = .{ .log_level = .info };

const Day10Error = error{
    NotEnoughArgs,
    InvalidPart,
};

// Follow trails on the map and return a count of number of valid trails from
// the given coordinates
fn follow_trails(seen: *std.AutoHashMap(Coord, void), map: []const u8, row_stride: i32, from: Coord, last_val: u8) !void {
    const height = @divTrunc(@as(i32, @intCast(map.len)), row_stride);
    // If the current coordinate is out of map bounds, obviously this isn't a valid trail.
    if (from.x < 0 or from.x >= row_stride or from.y < 0 or from.y >= height)
        return;

    // Current value should be 1 more than the last
    const curr_val = map[@intCast(from.flatten(row_stride))];
    if (curr_val != last_val + 1)
        return;

    // If the value is 9 then we reached the end of a valid trail
    if (curr_val == '9')
        try seen.put(from, {});

    // Otherwise try every direction and sum up the valid trails reached
    try follow_trails(seen, map, row_stride, from.sum(Coord.from_x(1)), curr_val);
    try follow_trails(seen, map, row_stride, from.sum(Coord.from_y(1)), curr_val);
    try follow_trails(seen, map, row_stride, from.sum(Coord.from_x(-1)), curr_val);
    try follow_trails(seen, map, row_stride, from.sum(Coord.from_y(-1)), curr_val);
}

pub fn main() !void {
    const argv = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, argv);

    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day10Error.NotEnoughArgs;
    }
    const file_path = argv[1];
    const part = try std.fmt.parseInt(i32, argv[2], 10);
    _ = part;

    // Read whole buffer and use it directly.
    const file = try std.fs.cwd().openFile(file_path, .{});
    const buf = try file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(i32));

    // Find stride between map rows
    var row_stride: usize = 0;
    while (row_stride < buf.len) : (row_stride += 1) {
        switch (buf[row_stride]) {
            '\r', '\n' => break,
            else => {},
        }
    } else unreachable;
    row_stride += 1;
    std.log.debug("Row stride is {d}", .{row_stride});
    var width = row_stride - 1;
    if (buf[width] == '\r')
        width -= 1;
    const height = buf.len / row_stride;
    std.log.debug("Map dimensions are {d}x{d}", .{ width, height });

    // Now go through every position with a 0 and search for valid trails
    var total_score: usize = 0;
    for (0..height) |y| {
        for (0..width) |x| {
            const c = Coord{ .x = @intCast(x), .y = @intCast(y) };
            var seen = std.AutoHashMap(Coord, void).init(std.heap.page_allocator);
            defer seen.deinit();
            try follow_trails(&seen, buf, @intCast(row_stride), c, '0' - 1);
            if (seen.count() > 0) {
                std.log.debug("Trailhead at {} has score {d}", .{ c, seen.count() });
            }
            total_score += seen.count();
        }
    }

    std.log.info("Total trails score was {d}", .{total_score});
}
