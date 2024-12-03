const std = @import("std");

const params = .{
    .min_step = @as(u32, 1),
    .max_step = @as(u32, 3),
};

const Direction = enum {
    Asc,
    Desc,
};

fn CheckState(comptime IterT: type) type {
    return struct {
        it: IterT,
        val: ?i32 = null,
        dir: ?Direction = null,
    };
}

fn check_report(comptime IterT: type, it: IterT) !bool {
    const DataType = i32;
    var state = CheckState(IterT){ .it = it };
    return while (state.it.next()) |entry| {
        const val = try std.fmt.parseInt(DataType, entry, 10);
        if (state.val) |prev_val| {
            const diff = val - prev_val;
            const dir = if (diff >= 0) Direction.Asc else Direction.Desc;
            if (state.dir) |prev_dir| {
                if (dir != prev_dir) {
                    break false;
                }
            }
            const abs_diff = @abs(diff);
            if (abs_diff < params.min_step or abs_diff > params.max_step) {
                break false;
            }
            state.dir = dir;
        }
        state.val = val;
    } else true;
}

pub const std_options: std.Options = .{ .log_level = .info };

pub fn main() !void {
    const argv = std.os.argv;
    if (argv.len != 2) {
        std.log.err("2 arguments were required but only passed {d}", .{argv.len});
    }
    const file_path = std.mem.span(argv[1]);
    const file = try std.fs.cwd().openFile(file_path, .{});
    var buf: [1024]u8 = undefined;
    var safe_count: u32 = 0;
    var total_count: usize = 0;
    while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| : (total_count += 1) {
        const entries = std.mem.splitScalar(u8, line, ' ');
        safe_count += if (try check_report(@TypeOf(entries), entries)) 1 else 0;
    }
    std.log.info("Total safe reports: {d}/{d}", .{ safe_count, total_count });
}
