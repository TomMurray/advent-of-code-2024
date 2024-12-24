const std = @import("std");

pub const std_options: std.Options = .{ .log_level = .info };

const Day11Error = error{
    NotEnoughArgs,
    InvalidPart,
};

fn log10_digits(in: anytype) !@TypeOf(in) {
    const digits = std.math.log_int(@TypeOf(in), 10, in);
    const power = try std.math.powi(@TypeOf(in), 10, digits);
    return if (power <= in)
        digits + 1
    else
        digits;
}

test "exact power of 10" {
    try std.testing.expect((try log10_digits(@as(usize, 1))) == 1);
    try std.testing.expect((try log10_digits(@as(usize, 10))) == 2);
    try std.testing.expect((try log10_digits(@as(usize, 100))) == 3);
    try std.testing.expect((try log10_digits(@as(usize, 1000))) == 4);
}

test "around exact power of 10" {
    try std.testing.expect((try log10_digits(@as(usize, 2))) == 1);
    try std.testing.expect((try log10_digits(@as(usize, 9))) == 1);
    try std.testing.expect((try log10_digits(@as(usize, 11))) == 2);
    try std.testing.expect((try log10_digits(@as(usize, 99))) == 2);
    try std.testing.expect((try log10_digits(@as(usize, 101))) == 3);
}

pub fn main() !void {
    const argv = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, argv);

    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day11Error.NotEnoughArgs;
    }
    const file_path = argv[1];
    const part = try std.fmt.parseInt(i32, argv[2], 10);
    _ = part;

    // Read in and parse input to a list of integers
    const file = try std.fs.cwd().openFile(file_path, .{});

    const IType = usize;
    var stones = std.ArrayList(IType).init(std.heap.page_allocator);
    defer stones.deinit();

    var data = try file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(IType));
    // Get rid of trailing newlines etc.
    while (data[data.len - 1] < '0' or data[data.len - 1] > '9')
        data = data[0 .. data.len - 1];
    var it = std.mem.splitScalar(u8, data, ' ');
    while (it.next()) |entry| {
        const val = try std.fmt.parseInt(IType, entry, 10);
        try stones.append(val);
    }

    // Now apply the rules iteratively. Use 2 buffers and swap back and forth
    var buf = try @TypeOf(stones).initCapacity(std.heap.page_allocator, stones.items.len);
    defer buf.deinit();
    const bufs = [2]*@TypeOf(stones){ &stones, &buf };
    var buf_idx: usize = 1;
    for (0..25) |i| {
        const from = bufs[buf_idx ^ 1];
        const to = bufs[buf_idx];
        std.log.debug("Blink {d}: {any}", .{ i, from.items });
        for (from.items) |stone| {
            // If the stone is engraved with the number 0, it is replaced by
            // a stone engraved with the number 1.
            if (stone == 0) {
                try to.append(1);
                continue;
            }
            // If the stone is engraved with a number that has an even number
            // of digits, it is replaced by two stones. The left half of the
            // digits are engraved on the new left stone, and the right half
            // of the digits are engraved on the new right stone. (The new numbers
            // don't keep extra leading zeroes: 1000 would become stones 10 and 0.)
            const digits = try log10_digits(stone);
            if (digits % 2 == 0) {
                const factor = try std.math.powi(IType, 10, digits / 2);
                const hi = stone / factor;
                const lo = stone - (hi * factor);
                try to.append(hi);
                try to.append(lo);
                continue;
            }
            // If none of the other rules apply, the stone is replaced by a new
            // stone; the old stone's number multiplied by 2024 is engraved on the
            // new stone.
            try to.append(stone * 2024);
        }
        try from.resize(0);
        buf_idx = buf_idx ^ 1;
    }

    const final_stones = bufs[buf_idx ^ 1];
    std.log.debug("Final stones set: {any}", .{final_stones.items});
    std.log.info("Final no. of stones: {d}", .{final_stones.items.len});
}
