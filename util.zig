const std = @import("std");

pub fn readLineOrEof(reader: anytype, buf: []u8) !?[]u8 {
    if (try reader.readUntilDelimiterOrEof(buf, '\n')) |line| {
        return if (line[line.len - 1] == '\r') line[0 .. line.len - 1] else line;
    }
    return null;
}
