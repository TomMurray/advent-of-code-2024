const std = @import("std");

pub const std_options: std.Options = .{ .log_level = .info };

const Day3Error = error{
    NotEnoughArgs,
    InvalidPart,
};

const State = union(enum) {
    // mul(<int>, <int>)
    Init,
    M,
    U,
    L,
    OpenBrace,
    FirstInt: i32,
    Comma: i32,
    SecondInt: struct { a: i32, b: i32 },
    // do()/don't()
    D,
    O,
    N,
    Apostrophe,
    T,
    EnableOpenBrace: bool,
};

const Parser = struct {
    ignoreDoDont: bool,

    state: State = State.Init,
    enabled: bool = true,

    result: i32 = 0,

    fn parseBytes(self: *Parser, bytes: []const u8) void {
        for (bytes) |c| {
            std.log.debug("Next char '{c}', current state {any}", .{ c, self.state });
            self.state = switch (self.state) {
                State.Init => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    else => State.Init,
                },
                State.M => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    'u' => State.U,
                    else => State.Init,
                },
                State.U => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    'l' => State.L,
                    else => State.Init,
                },
                State.L => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    '(' => State.OpenBrace,
                    else => State.Init,
                },
                State.OpenBrace => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    '0'...'9' => .{ .FirstInt = c - '0' },
                    else => State.Init,
                },
                State.FirstInt => |curr_val| switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    '0'...'9' => .{ .FirstInt = curr_val * 10 + (c - '0') },
                    ',' => .{ .Comma = curr_val },
                    else => State.Init,
                },
                State.Comma => |a| switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    '0'...'9' => .{ .SecondInt = .{ .a = a, .b = c - '0' } },
                    else => State.Init,
                },
                State.SecondInt => |curr_val| switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    '0'...'9' => .{ .SecondInt = .{
                        .a = curr_val.a,
                        .b = curr_val.b * 10 + (c - '0'),
                    } },
                    ')' => blk: {
                        // Finish, add to total
                        const product = curr_val.a * curr_val.b;
                        std.log.debug("Add {d}*{d}={d} to total {d} -> {d}", .{ curr_val.a, curr_val.b, product, self.result, self.result + product });
                        if (self.enabled) {
                            self.result += curr_val.a * curr_val.b;
                        }
                        break :blk State.Init;
                    },
                    else => State.Init,
                },
                State.D => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    'o' => State.O,
                    else => State.Init,
                },
                State.O => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    'n' => State.N,
                    '(' => .{ .EnableOpenBrace = true },
                    else => State.Init,
                },
                State.N => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    '\'' => State.Apostrophe,
                    else => State.Init,
                },
                State.Apostrophe => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    't' => State.T,
                    else => State.Init,
                },
                State.T => switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    '(' => .{ .EnableOpenBrace = false },
                    else => State.Init,
                },
                State.EnableOpenBrace => |enable| switch (c) {
                    'm' => State.M,
                    'd' => State.D,
                    ')' => blk: {
                        self.enabled = self.ignoreDoDont or enable;
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
    if (argv.len != 3) {
        std.log.err("3 args required but only {d} provided", .{argv.len});
        return Day3Error.NotEnoughArgs;
    }
    const file_path = std.mem.span(argv[1]);
    const part = try std.fmt.parseInt(i32, std.mem.span(argv[2]), 10);

    switch (part) {
        1, 2 => {
            std.log.info("Calculating part {d} solution...", .{part});
        },
        else => return Day3Error.InvalidPart,
    }

    const file = try std.fs.cwd().openFile(file_path, .{});

    var parser = Parser{ .ignoreDoDont = part == 1 };

    var buf: [1024]u8 = undefined;
    var bytes: usize = try file.read(&buf);
    while (bytes != 0) : (bytes = try file.read(&buf)) {
        std.log.debug("Read {d} bytes: {s}", .{ bytes, buf[0..bytes] });
        parser.parseBytes(buf[0..bytes]);
    }

    std.log.info("Final result was {d}", .{parser.result});
}
