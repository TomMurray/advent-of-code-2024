const std = @import("std");
const util = @import("util.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    // Input data file path as argument 1
    std.debug.assert(argv.len == 2);
    const file_path = argv[1];
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    // Read input line by line
    var buf: [1024]u8 = undefined;

    const NumT = i32;

    var lists = .{
        .a = std.ArrayList(NumT).init(allocator),
        .b = std.ArrayList(NumT).init(allocator),
    };
    defer lists.a.deinit();
    defer lists.b.deinit();

    while (try util.readLineOrEof(file.reader(), &buf)) |line| {
        if (line.len == 0) continue;
        var iter = std.mem.splitSequence(u8, line, "   ");
        try lists.a.append(try std.fmt.parseInt(NumT, iter.next().?, 10));
        try lists.b.append(try std.fmt.parseInt(NumT, iter.next().?, 10));
    }

    // Sort both lists
    std.sort.heap(NumT, lists.a.items, {}, std.sort.asc(NumT));
    std.sort.heap(NumT, lists.b.items, {}, std.sort.asc(NumT));

    // Now calculate the difference by iterating both concurrently
    const n_items = lists.a.items.len;
    std.debug.assert(lists.b.items.len == n_items);
    var total_diff: u32 = 0;
    for (lists.a.items, lists.b.items) |a, b| {
        total_diff += @abs(b - a);
    }
    std.log.info("Total difference was {d}", .{total_diff});

    // Now calculate similarity score
    var total_sim: i32 = 0;
    var b_iter = lists.b.items;

    var last_sim: i32 = 0;
    var last_a: ?i32 = null;
    for (lists.a.items) |a| {
        // Deal with repeat values in list a:
        if (last_a) |prev| {
            if (prev == a) {
                total_sim += last_sim;
                continue;
            }
        }
        // If we've run out of entries in b, finish
        if (b_iter.len == 0)
            break;

        // Skip entries less than current entry in a.
        while (b_iter.len > 0 and b_iter[0] < a)
            b_iter = b_iter[1..];
        // Count entries equal to current entry in a.
        last_sim = 0;
        while (b_iter.len > 0 and b_iter[0] == a) {
            b_iter = b_iter[1..];
            last_sim += a;
        }
        total_sim += last_sim;
        last_a = a;
    }
    std.log.info("Total similarity was {d}", .{total_sim});
}
