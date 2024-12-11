const std = @import("std");
const util = @import("util.zig");

pub const std_options: std.Options = .{ .log_level = .info };

const Day8Error = error{
    NotEnoughArgs,
    InvalidPart,
};

const Coord = struct {
    x: i32,
    y: i32,

    pub fn format(
        self: Coord,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("({d},{d})", .{ self.x, self.y });
    }

    pub fn flatten(self: *const Coord, width: i32) i32 {
        return self.*.y * width + self.*.x;
    }

    pub fn diff(self: *const Coord, other: Coord) Coord {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn sum(self: *const Coord, other: Coord) Coord {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn antinode(self: *const Coord, other: Coord) Coord {
        return self.sum(self.diff(other));
    }

    pub fn inbounds(self: *const Coord, bounds: Coord) bool {
        return self.x >= 0 and self.x < bounds.x and self.y >= 0 and self.y < bounds.y;
    }
};

pub fn main() !void {
    const argv = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, argv);

    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day8Error.NotEnoughArgs;
    }
    const file_path = argv[1];
    const part = try std.fmt.parseInt(i32, argv[2], 10);
    _ = part;

    const file = try std.fs.cwd().openFile(file_path, .{});

    // Store a set of coordinates per-frequency
    var freq_coords = std.AutoHashMap(u8, std.ArrayList(Coord)).init(std.heap.page_allocator);
    defer freq_coords.deinit();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var buf: [1024]u8 = undefined;
    var h: i32 = 0;
    var w: i32 = 0;
    while (try util.readLineOrEof(file.reader(), &buf)) |line| : (h += 1) {
        std.log.debug("Input line: {s}", .{line});

        for (line, 0..) |c, _x| {
            switch (c) {
                'a'...'z', 'A'...'Z', '0'...'9' => {
                    const x: i32 = @intCast(_x);
                    const coord = Coord{ .x = x, .y = h };
                    if (freq_coords.getPtr(c)) |coords| {
                        try coords.append(coord);
                    } else {
                        var new_list = std.ArrayList(Coord).init(allocator);
                        try new_list.append(coord);
                        try freq_coords.put(c, new_list);
                    }
                },
                else => {},
            }
        }

        w = @intCast(line.len);
    }
    const bounds = Coord{ .x = w, .y = h };

    var it = freq_coords.iterator();
    var antinodes =
        std.AutoHashMap(Coord, void).init(std.heap.page_allocator);
    defer antinodes.deinit();

    while (it.next()) |entry| {
        std.log.debug("Checks for freq '{c}'", .{entry.key_ptr.*});

        const items = entry.value_ptr.items;
        // For every unique pairing of coordinates with the same frequency
        for (items[0..(items.len - 1)], 0..) |a, i| {
            for (items[(i + 1)..]) |b| {
                // Compute both the forward and reverse signal resonance
                const ab = a.antinode(b);
                const ba = b.antinode(a);
                std.log.debug("  {} <=> {}: {} and {}", .{ a, b, ab, ba });

                if (ab.inbounds(bounds))
                    try antinodes.put(ab, {});
                if (ba.inbounds(bounds))
                    try antinodes.put(ba, {});
            }
        }
    }

    std.log.info("Total unique antinodes: {d}", .{antinodes.count()});
}
