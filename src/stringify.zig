//! Stringify - Converts Value trees to ZON source code.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Value = @import("value.zig").Value;

/// Stringification options.
pub const StringifyOptions = struct {
    indent: usize = 4,
    initial_indent: usize = 0,
};

pub const StringifyError = Allocator.Error;

pub const Buffer = struct {
    allocator: Allocator,
    data: std.ArrayListUnmanaged(u8),

    pub fn init(allocator: Allocator) Buffer {
        return .{
            .allocator = allocator,
            .data = .empty,
        };
    }

    pub fn deinit(self: *Buffer) void {
        self.data.deinit(self.allocator);
    }

    pub fn append(self: *Buffer, char: u8) StringifyError!void {
        try self.data.append(self.allocator, char);
    }

    pub fn appendSlice(self: *Buffer, slice: []const u8) StringifyError!void {
        try self.data.appendSlice(self.allocator, slice);
    }

    pub fn appendNTimes(self: *Buffer, char: u8, count: usize) StringifyError!void {
        try self.data.appendNTimes(self.allocator, char, count);
    }

    pub fn toOwnedSlice(self: *Buffer) StringifyError![]u8 {
        return self.data.toOwnedSlice(self.allocator);
    }
};

/// Converts a Value to a ZON string. Caller must free.
pub fn stringify(allocator: Allocator, value: *const Value, options: StringifyOptions) StringifyError![]u8 {
    var buffer = Buffer.init(allocator);
    errdefer buffer.deinit();

    try stringifyValue(&buffer, value, options.initial_indent, options.indent);

    return buffer.toOwnedSlice();
}

fn stringifyValue(buffer: *Buffer, value: *const Value, indent: usize, indent_size: usize) StringifyError!void {
    switch (value.*) {
        .null_val => try buffer.appendSlice("null"),
        .bool_val => |b| try buffer.appendSlice(if (b) "true" else "false"),
        .number => |n| switch (n) {
            .int => |i| {
                var num_buf: [32]u8 = undefined;
                const slice = std.fmt.bufPrint(&num_buf, "{d}", .{i}) catch unreachable;
                try buffer.appendSlice(slice);
            },
            .float => |f| {
                var num_buf: [64]u8 = undefined;
                const slice = std.fmt.bufPrint(&num_buf, "{d}", .{f}) catch unreachable;
                try buffer.appendSlice(slice);
            },
        },
        .string => |s| try stringifyString(buffer, s),
        .object => |o| try stringifyObject(buffer, &o, indent, indent_size),
        .array => |a| try stringifyArray(buffer, &a, indent, indent_size),
    }
}

fn stringifyString(buffer: *Buffer, s: []const u8) StringifyError!void {
    try buffer.append('"');
    for (s) |c| {
        switch (c) {
            '\n' => try buffer.appendSlice("\\n"),
            '\r' => try buffer.appendSlice("\\r"),
            '\t' => try buffer.appendSlice("\\t"),
            '\\' => try buffer.appendSlice("\\\\"),
            '"' => try buffer.appendSlice("\\\""),
            else => try buffer.append(c),
        }
    }
    try buffer.append('"');
}

fn stringifyObject(buffer: *Buffer, obj: *const Value.Object, indent: usize, indent_size: usize) StringifyError!void {
    if (obj.count() == 0) {
        try buffer.appendSlice(".{}");
        return;
    }

    try buffer.appendSlice(".{\n");

    const keys = try obj.keys(buffer.allocator);
    defer buffer.allocator.free(keys);

    std.mem.sort([]const u8, keys, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);

    for (keys) |key| {
        const val_ptr = obj.entries.getPtr(key).?;

        try appendIndent(buffer, indent + indent_size);
        try buffer.append('.');
        try buffer.appendSlice(key);
        try buffer.appendSlice(" = ");
        try stringifyValue(buffer, val_ptr, indent + indent_size, indent_size);
        try buffer.appendSlice(",\n");
    }

    try appendIndent(buffer, indent);
    try buffer.append('}');
}

fn stringifyArray(buffer: *Buffer, arr: *const Value.Array, indent: usize, indent_size: usize) StringifyError!void {
    if (arr.len() == 0) {
        try buffer.appendSlice(".{}");
        return;
    }

    try buffer.appendSlice(".{\n");

    for (arr.items.items) |*item| {
        try appendIndent(buffer, indent + indent_size);
        try stringifyValue(buffer, item, indent + indent_size, indent_size);
        try buffer.appendSlice(",\n");
    }

    try appendIndent(buffer, indent);
    try buffer.append('}');
}

fn appendIndent(buffer: *Buffer, count: usize) StringifyError!void {
    try buffer.appendNTimes(' ', count);
}
