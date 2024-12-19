const std = @import("std");

pub const std_options: std.Options = .{ .log_level = .debug };

const Day9Error = error{
    NotEnoughArgs,
    InvalidPart,
};

pub fn main() !void {
    const argv = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, argv);

    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day9Error.NotEnoughArgs;
    }
    const file_path = argv[1];
    const part = try std.fmt.parseInt(i32, argv[2], 10);
    _ = part;

    const file = try std.fs.cwd().openFile(file_path, .{});
    const buf = try file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(i32));

    const pairs = buf.len >> 1;

    // Work forwards through the list, keeping track of the current block position.
    // When free space is encountered, take file blocks from the back of the list.
    // Continue until the end of the list is encountered
    var checksum: usize = 0;
    var block_sum: usize = 0;
    var rev_idx: usize = (pairs - 1) << 1;
    for (0..pairs) |fid| {
        const idx = fid << 1;
        var used_blocks: usize = @intCast(buf[idx] - '0');
        var free_blocks: usize = if (fid + 1 < pairs) @intCast(buf[idx + 1] - '0') else 0;
        while (used_blocks != 0) : ({
            used_blocks -= 1;
            block_sum += 1;
        }) {
            checksum += block_sum * fid;
        }
        while (free_blocks != 0 and rev_idx > idx) : ({
            free_blocks -= 1;
            block_sum += 1;
        }) {
            while (rev_idx > idx and (buf[rev_idx] - '0') == 0)
                rev_idx -= 2;
            if (rev_idx <= idx)
                break;
            checksum += block_sum * (rev_idx >> 1);
            buf[rev_idx] -= 1;
        }
        while (free_blocks != 0) : (free_blocks -= 1) {
            block_sum += 1;
        }
    }
    std.debug.print("\n", .{});
    std.log.info("Checksum after compaction was {d}", .{checksum});
}
