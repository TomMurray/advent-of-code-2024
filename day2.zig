const std = @import("std");

const params = .{
    .min_step = @as(u32, 1),
    .max_step = @as(u32, 3),
};

const Direction = enum {
    Asc,
    Desc,
};

pub const std_options: std.Options = .{ .log_level = .info };

pub fn main() !void {
    const argv = std.os.argv;
    if (argv.len != 2) {
        std.log.err("2 arguments were required but only passed {d}", .{argv.len});
    }
    const DataType = i32;
    const file_path = std.mem.span(argv[1]);
    const file = try std.fs.cwd().openFile(file_path, .{});
    var buf: [1024]u8 = undefined;
    var safe_count: u32 = 0;
    var total_count: usize = 0;
    while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| : (total_count += 1) {
        var entries = std.mem.splitScalar(u8, line, ' ');
        var prev_val: ?i32 = null;
        var prev_dir: ?Direction = null;
        std.log.debug("Started new line", .{});
        safe_count += while (entries.next()) |entry| {
            const v = try std.fmt.parseInt(DataType, entry, 10);
            std.log.debug("  Current value is {d}", .{v});
            if (prev_val) |pv| {
                const diff = v - pv;
                const dir = if (diff >= 0) Direction.Asc else Direction.Desc;
                std.log.debug("diff={d}, dir is {s}", .{ diff, @tagName(dir) });
                if (prev_dir) |pd| {
                    if (dir != pd) {
                        std.log.debug("Direction didn't match, aborting", .{});
                        break 0;
                    }
                }
                const abs_diff = @abs(diff);
                if (abs_diff < params.min_step or abs_diff > params.max_step) {
                    std.log.debug("Absolute difference was outside allowed range: {d}", .{abs_diff});
                    break 0;
                }
                prev_dir = dir;
            }
            prev_val = v;
        } else 1;
    }
    std.log.info("Total safe reports: {d}/{d}", .{ safe_count, total_count });
}
