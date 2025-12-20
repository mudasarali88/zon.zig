//! Value - Core data types for ZON representation.

const std = @import("std");
const Allocator = std.mem.Allocator;

/// ZON value types.
pub const Value = union(enum) {
    null_val,
    bool_val: bool,
    number: Number,
    string: []const u8,
    object: Object,
    array: Array,

    /// Numeric value.
    pub const Number = union(enum) {
        int: i64,
        float: f64,
    };

    /// Object type - key-value map.
    pub const Object = struct {
        allocator: Allocator,
        entries: std.StringHashMapUnmanaged(Value),

        pub fn init(allocator: Allocator) Object {
            return .{
                .allocator = allocator,
                .entries = .{},
            };
        }

        pub fn deinit(self: *Object) void {
            var it = self.entries.iterator();
            while (it.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
                entry.value_ptr.deinit(self.allocator);
            }
            self.entries.deinit(self.allocator);
        }

        pub fn get(self: *const Object, key: []const u8) ?*Value {
            return self.entries.getPtr(key);
        }

        pub fn put(self: *Object, key: []const u8, value: Value) !void {
            const owned_key = try self.allocator.dupe(u8, key);
            errdefer self.allocator.free(owned_key);

            if (self.entries.getPtr(key)) |existing| {
                existing.deinit(self.allocator);
                existing.* = value;
                self.allocator.free(owned_key);
            } else {
                try self.entries.put(self.allocator, owned_key, value);
            }
        }

        pub fn remove(self: *Object, key: []const u8) bool {
            if (self.entries.fetchRemove(key)) |kv| {
                self.allocator.free(kv.key);
                var v = kv.value;
                v.deinit(self.allocator);
                return true;
            }
            return false;
        }

        pub fn count(self: *const Object) usize {
            return self.entries.count();
        }

        pub fn keys(self: *const Object, allocator: Allocator) ![][]const u8 {
            const key_count = self.entries.count();
            const result = try allocator.alloc([]const u8, key_count);
            var i: usize = 0;
            var it = self.entries.keyIterator();
            while (it.next()) |key| {
                result[i] = key.*;
                i += 1;
            }
            return result;
        }
    };

    /// Array type - ordered list of values.
    pub const Array = struct {
        allocator: Allocator,
        items: std.ArrayListUnmanaged(Value),

        pub fn init(allocator: Allocator) Array {
            return .{
                .allocator = allocator,
                .items = .{},
            };
        }

        pub fn deinit(self: *Array) void {
            for (self.items.items) |*item| {
                item.deinit(self.allocator);
            }
            self.items.deinit(self.allocator);
        }

        pub fn append(self: *Array, value: Value) !void {
            try self.items.append(self.allocator, value);
        }

        pub fn get(self: *const Array, index: usize) ?*Value {
            if (index >= self.items.items.len) return null;
            return &self.items.items[index];
        }

        pub fn len(self: *const Array) usize {
            return self.items.items.len;
        }
    };

    /// Frees all memory.
    pub fn deinit(self: *Value, allocator: Allocator) void {
        switch (self.*) {
            .string => |s| allocator.free(s),
            .object => |*o| o.deinit(),
            .array => |*a| a.deinit(),
            else => {},
        }
    }

    /// Creates a deep copy.
    pub fn clone(self: *const Value, allocator: Allocator) !Value {
        return switch (self.*) {
            .null_val => .null_val,
            .bool_val => |b| .{ .bool_val = b },
            .number => |n| .{ .number = n },
            .string => |s| .{ .string = try allocator.dupe(u8, s) },
            .object => |o| blk: {
                var new_obj = Object.init(allocator);
                var it = o.entries.iterator();
                while (it.next()) |entry| {
                    const cloned_val = try entry.value_ptr.clone(allocator);
                    try new_obj.put(entry.key_ptr.*, cloned_val);
                }
                break :blk .{ .object = new_obj };
            },
            .array => |a| blk: {
                var new_arr = Array.init(allocator);
                for (a.items.items) |*item| {
                    const cloned_item = try item.clone(allocator);
                    try new_arr.append(cloned_item);
                }
                break :blk .{ .array = new_arr };
            },
        };
    }

    pub fn asString(self: *const Value) ?[]const u8 {
        return switch (self.*) {
            .string => |s| s,
            else => null,
        };
    }

    pub fn asBool(self: *const Value) ?bool {
        return switch (self.*) {
            .bool_val => |b| b,
            else => null,
        };
    }

    pub fn asInt(self: *const Value) ?i64 {
        return switch (self.*) {
            .number => |n| switch (n) {
                .int => |i| i,
                .float => |f| if (@abs(f - @trunc(f)) < 0.0001) @as(i64, @intFromFloat(f)) else null,
            },
            else => null,
        };
    }

    pub fn asFloat(self: *const Value) ?f64 {
        return switch (self.*) {
            .number => |n| switch (n) {
                .float => |f| f,
                .int => |i| @floatFromInt(i),
            },
            else => null,
        };
    }

    pub fn isNull(self: *const Value) bool {
        return self.* == .null_val;
    }

    pub fn asObject(self: *Value) ?*Object {
        return switch (self.*) {
            .object => |*o| o,
            else => null,
        };
    }

    pub fn asArray(self: *Value) ?*Array {
        return switch (self.*) {
            .array => |*a| a,
            else => null,
        };
    }
};
