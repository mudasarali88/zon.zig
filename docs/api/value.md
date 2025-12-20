# Value Types

The `Value` type represents all possible ZON values.

## Value Union

```zig
pub const Value = union(enum) {
    null_val,
    bool_val: bool,
    number: Number,
    string: []const u8,
    object: Object,
    array: Array,
};
```

## Number Type

```zig
pub const Number = union(enum) {
    int: i64,
    float: f64,
};
```

Numbers can be integers or floats. Large hex values (like fingerprints) are stored as i64 using bit-casting.

## Object Type

Objects are key-value maps:

```zig
pub const Object = struct {
    allocator: Allocator,
    entries: std.StringHashMapUnmanaged(Value),

    pub fn init(allocator: Allocator) Object;
    pub fn deinit(self: *Object) void;
    pub fn get(self: *Object, key: []const u8) ?*Value;
    pub fn put(self: *Object, key: []const u8, value: Value) !void;
    pub fn remove(self: *Object, key: []const u8) bool;
    pub fn count(self: *const Object) usize;
    pub fn keys(self: *const Object, allocator: Allocator) ![][]const u8;
};
```

## Array Type

Arrays are ordered lists:

```zig
pub const Array = struct {
    allocator: Allocator,
    items: std.ArrayListUnmanaged(Value),

    pub fn init(allocator: Allocator) Array;
    pub fn deinit(self: *Array) void;
    pub fn append(self: *Array, value: Value) !void;
    pub fn get(self: *const Array, index: usize) ?*const Value;
    pub fn len(self: *const Array) usize;
};
```

## Value Methods

### Type Checking

```zig
pub fn asString(self: *const Value) ?[]const u8;
pub fn asBool(self: *const Value) ?bool;
pub fn asInt(self: *const Value) ?i64;
pub fn asFloat(self: *const Value) ?f64;
pub fn asObject(self: *Value) ?*Object;
pub fn asArray(self: *Value) ?*Array;
pub fn isNull(self: *const Value) bool;
```

### Memory Management

```zig
pub fn deinit(self: *Value, allocator: Allocator) void;
pub fn clone(self: *const Value, allocator: Allocator) !Value;
```

## ZON Type Mapping

| ZON Syntax            | Value Type                              |
| --------------------- | --------------------------------------- |
| `"string"`            | `.string`                               |
| `123`                 | `.number.int`                           |
| `3.14`                | `.number.float`                         |
| `0xFF`                | `.number.int`                           |
| `true`/`false`        | `.bool_val`                             |
| `null`                | `.null_val`                             |
| `.{ .key = value }`   | `.object`                               |
| `.{ value1, value2 }` | `.array`                                |
| `.identifier`         | `.string` (identifier stored as string) |
