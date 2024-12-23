const std = @import("std");

pub const Coord = struct {
    x: i32,
    y: i32,

    pub fn from_x(val: i32) Coord {
        return .{
            .x = val,
            .y = 0,
        };
    }

    pub fn from_y(val: i32) Coord {
        return .{
            .x = 0,
            .y = val,
        };
    }

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
