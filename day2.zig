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

fn check_report(comptime StateT: type, state_: StateT, remaining_failures: u32) !bool {
    var state = state_;
    const DataType = i32;
    var prev_state: ?StateT = null;
    return while (state.it.next()) |entry| {
        const val = try std.fmt.parseInt(DataType, entry, 10);
        if (state.val) |prev_val| {
            const diff = val - prev_val;
            const dir = if (diff >= 0) Direction.Asc else Direction.Desc;
            const abs_diff = @abs(diff);
            if (abs_diff < params.min_step or abs_diff > params.max_step or
                if (state.dir) |prev_dir| prev_dir != dir else false)
            {
                if (remaining_failures > 0) {
                    if (prev_state) |ps|
                        if (try check_report(StateT, ps, remaining_failures - 1))
                            break true;
                    if (try check_report(StateT, state, remaining_failures - 1))
                        break true;
                }
                break false;
            }
            if (prev_state) |*ps| {
                ps.*.dir = state.dir;
            }
            state.dir = dir;
        }
        if (prev_state == null) {
            prev_state = StateT{ .it = state.it };
        }
        if (prev_state) |*ps| {
            ps.*.val = state.val;
        }
        state.val = val;
    } else true;
}

const Day2Error = error{
    NotEnoughArgs,
};

pub const std_options: std.Options = .{ .log_level = .info };

pub fn main() !void {
    const argv = std.os.argv;
    if (argv.len != 3) {
        std.log.err("3 arguments were required but only passed {d}.\n  ./day2 <path to input> <max report entries to ignore (0 for part 1, 2 for part 2)>", .{argv.len});
        return Day2Error.NotEnoughArgs;
    }
    const file_path = std.mem.span(argv[1]);
    const max_failures = try std.fmt.parseInt(u32, std.mem.span(argv[2]), 10);
    const file = try std.fs.cwd().openFile(file_path, .{});
    var buf: [1024]u8 = undefined;
    var safe_count: u32 = 0;
    var total_count: usize = 0;
    while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| : (total_count += 1) {
        const entries = std.mem.splitScalar(u8, line, ' ');
        const init_state = CheckState(@TypeOf(entries)){ .it = entries };
        safe_count += if (try check_report(@TypeOf(init_state), init_state, max_failures)) 1 else 0;
    }
    std.log.info("Total safe reports: {d}/{d}", .{ safe_count, total_count });
}
