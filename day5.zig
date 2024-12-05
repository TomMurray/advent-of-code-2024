const std = @import("std");

const Day5Error = error{
    NotEnoughArgs,
    InvalidPart,
};

pub fn main() !void {
    const argv = std.os.argv;
    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day5Error.NotEnoughArgs;
    }
    const file_path = std.mem.span(argv[1]);
    const part = try std.fmt.parseInt(i32, std.mem.span(argv[2]), 10);

    const file = try std.fs.cwd().openFile(file_path, .{});

    // First parse constraints graph
    var buf: [1024]u8 = undefined;
    const ConstraintSet = std.AutoArrayHashMap(i32, std.ArrayList(i32));

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var constraints = ConstraintSet.init(allocator);

    while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0)
            break;
        var parts = std.mem.splitScalar(u8, line, '|');
        const from = try std.fmt.parseInt(i32, parts.next().?, 10);
        const to = try std.fmt.parseInt(i32, parts.next().?, 10);

        if (constraints.getPtr(from)) |constraint| {
            try constraint.append(to);
        } else {
            var newlist = std.ArrayList(i32).init(allocator);
            try newlist.append(to);
            try constraints.put(from, newlist);
        }
    }

    switch (part) {
        1 => {
            var mid_page_sum: i32 = 0;
            while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
                var it = std.mem.splitScalar(u8, line, ',');

                var update = std.ArrayList(i32).init(allocator);
                while (it.next()) |s| {
                    try update.append(try std.fmt.parseInt(i32, s, 10));
                }

                var seen_pages = std.AutoArrayHashMap(i32, void).init(allocator);

                const valid_update = outer: for (update.items) |page| {
                    // For each page, check that none of the pages that must come after it
                    // are in the set of pages that have already been seen.
                    if (constraints.get(page)) |*constraint|
                        for (constraint.items) |cpage|
                            if (seen_pages.contains(cpage))
                                break :outer false;

                    try seen_pages.put(page, {});
                } else true;

                if (valid_update) {
                    const mid_page = update.items[update.items.len / 2];
                    mid_page_sum += mid_page;
                }
            }
            std.log.info("Mid page sum: {d}", .{mid_page_sum});
        },
        else => return Day5Error.InvalidPart,
    }
}
