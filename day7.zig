const std = @import("std");
const util = @import("util.zig");

pub const std_options: std.Options = .{ .log_level = .info };

const Day7Error = error{
    NotEnoughArgs,
    InvalidPart,
};

const Operation = enum {
    Add,
    Mul,

    pub fn compute(self: *const Operation, a: i64, b: i64) i64 {
        return switch (self.*) {
            Operation.Add => a + b,
            Operation.Mul => a * b,
        };
    }
};

fn permute(target: i64, curr: i64, _it: anytype) !bool {
    var it = _it;
    if (it.next()) |token| {
        const val = try std.fmt.parseInt(i64, token, 10);
        // Try all permutations of the operations to reach the result
        inline for (std.meta.fields(Operation)) |_op| {
            const op: Operation = @enumFromInt(_op.value);
            const combined = op.compute(curr, val);
            if (try permute(target, combined, it)) return true;
        }
    }
    return target == curr;
}

pub fn main() !void {
    const argv = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, argv);

    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day7Error.NotEnoughArgs;
    }
    const file_path = argv[1];
    const part = try std.fmt.parseInt(i32, argv[2], 10);

    const file = try std.fs.cwd().openFile(file_path, .{});

    switch (part) {
        1 => {
            var buf: [1024]u8 = undefined;
            var total: i64 = 0;
            while (try util.readLineOrEof(file.reader(), &buf)) |line| {
                std.log.debug("Input line: {s}", .{line});
                var it = std.mem.splitScalar(u8, line, ':');
                const res = try std.fmt.parseInt(i64, it.next().?, 10);
                std.log.debug("Result = {d}", .{res});
                it = std.mem.splitScalar(u8, it.next().?, ' ');
                _ = it.next().?;
                const curr = try std.fmt.parseInt(i64, it.next().?, 10);
                std.log.debug("First = {d}", .{curr});

                if (try permute(res, curr, it)) {
                    total += res;
                }
            }

            std.log.info("Total calibrated result was {d}", .{total});
        },
        else => return Day7Error.InvalidPart,
    }
}
