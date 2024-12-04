const std = @import("std");

pub const std_options: std.Options = .{ .log_level = .info };

const Day3Error = error{
    NotEnoughArgs,
};

const State = union(enum) {
    Init,
    M,
    U,
    L,
    OpenBrace,
    FirstInt: i32,
    Comma: i32,
    SecondInt: struct { a: i32, b: i32 },
};

const Parser = struct {
    state: State = State.Init,

    result: i32 = 0,

    fn parseBytes(self: *Parser, bytes: []const u8) void {
        for (bytes) |c| {
            std.log.debug("Next char '{c}', current state {any}", .{ c, self.state });
            self.state = switch (self.state) {
                State.Init => switch (c) {
                    'm' => State.M,
                    else => State.Init,
                },
                State.M => switch (c) {
                    'm' => State.M,
                    'u' => State.U,
                    else => State.Init,
                },
                State.U => switch (c) {
                    'm' => State.M,
                    'l' => State.L,
                    else => State.Init,
                },
                State.L => switch (c) {
                    'm' => State.M,
                    '(' => State.OpenBrace,
                    else => State.Init,
                },
                State.OpenBrace => switch (c) {
                    'm' => State.M,
                    '0'...'9' => .{ .FirstInt = c - '0' },
                    else => State.Init,
                },
                State.FirstInt => |curr_val| switch (c) {
                    'm' => State.M,
                    '0'...'9' => .{ .FirstInt = curr_val * 10 + (c - '0') },
                    ',' => .{ .Comma = curr_val },
                    else => State.Init,
                },
                State.Comma => |a| switch (c) {
                    'm' => State.M,
                    '0'...'9' => .{ .SecondInt = .{ .a = a, .b = c - '0' } },
                    else => State.Init,
                },
                State.SecondInt => |curr_val| switch (c) {
                    'm' => State.M,
                    '0'...'9' => .{ .SecondInt = .{
                        .a = curr_val.a,
                        .b = curr_val.b * 10 + (c - '0'),
                    } },
                    ')' => blk: {
                        // Finish, add to total
                        const product = curr_val.a * curr_val.b;
                        std.log.debug("Add {d}*{d}={d} to total {d} -> {d}", .{ curr_val.a, curr_val.b, product, self.result, self.result + product });
                        self.result += curr_val.a * curr_val.b;
                        break :blk State.Init;
                    },
                    else => State.Init,
                },
            };
        }
    }
};

pub fn main() !void {
    const argv = std.os.argv;
    if (argv.len != 2) {
        std.log.err("2 args required but only {d} provided", .{argv.len});
        return Day3Error.NotEnoughArgs;
    }
    const file_path = std.mem.span(argv[1]);
    const file = try std.fs.cwd().openFile(file_path, .{});

    var parser = Parser{};

    var buf: [1024]u8 = undefined;
    var bytes: usize = try file.read(&buf);
    while (bytes != 0) : (bytes = try file.read(&buf)) {
        std.log.debug("Read {d} bytes: {s}", .{ bytes, buf[0..bytes] });
        parser.parseBytes(buf[0..bytes]);
    }

    std.log.info("Final result was {d}", .{parser.result});
}
