const std = @import("std");

pub fn main() !void {
    const argv = std.os.argv;
    // Input data file path as argument 1
    std.debug.assert(argv.len == 2);
    const file_path = std.mem.span(argv[1]);
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const allocator = std.heap.page_allocator;

    // Read input line by line
    var buf: [1024]u8 = undefined;

    const NumT = i32;
    var list_a = std.ArrayList(NumT).init(allocator);
    defer list_a.deinit();
    var list_b = std.ArrayList(NumT).init(allocator);
    defer list_b.deinit();
    while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var iter = std.mem.splitSequence(u8, line, "   ");
        try list_a.append(try std.fmt.parseInt(NumT, iter.next().?, 10));
        try list_b.append(try std.fmt.parseInt(NumT, iter.next().?, 10));
    }

    // Sort both lists
    std.sort.heap(NumT, list_a.items, {}, std.sort.asc(NumT));
    std.sort.heap(NumT, list_b.items, {}, std.sort.asc(NumT));

    // Now calculate the difference by iterating both concurrently
    const n_items = list_a.items.len;
    std.debug.assert(list_b.items.len == n_items);
    var total_diff: u32 = 0;
    for (list_a.items, list_b.items) |a, b| {
        total_diff += @abs(b - a);
    }
    std.log.info("Total difference was {d}", .{total_diff});
}
