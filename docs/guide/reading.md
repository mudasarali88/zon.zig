# Reading ZON Files

Learn how to read and parse ZON files with zon.zig.

## Opening a File

Use `zon.open` to read an existing ZON file:

```zig
const zon = @import("zon");

var doc = try zon.open(allocator, "config.zon");
defer doc.deinit();
```

## Parsing a String

Use `zon.parse` to parse ZON from a string:

```zig
const source =
    \\.{
    \\    .name = "myapp",
    \\    .version = "1.0.0",
    \\}
;

var doc = try zon.parse(allocator, source);
defer doc.deinit();
```

## Reading Values

### String Values

```zig
const name = doc.getString("name");
if (name) |n| {
    std.debug.print("Name: {s}\n", .{n});
}

// With default
const host = doc.getString("host") orelse "localhost";
```

### Numeric Values

```zig
const port = doc.getInt("port");           // ?i64
const timeout = doc.getFloat("timeout");   // ?f64
const count = doc.getNumber("count");      // ?f64 (alias for getFloat)

// With defaults
const max_conn = doc.getInt("max_connections") orelse 100;
```

### Boolean Values

```zig
const enabled = doc.getBool("enabled");
if (enabled) |e| {
    if (e) {
        std.debug.print("Feature is enabled\n", .{});
    }
}
```

### Null Values

```zig
if (doc.isNull("optional_field")) {
    std.debug.print("Field is explicitly null\n", .{});
}
```

## Supported Formats

### Identifier Values

ZON supports identifier values like `.zon`:

```zig
const source = ".{ .name = .my_package }";
var doc = try zon.parse(allocator, source);
defer doc.deinit();

// Identifier is stored as string
const name = doc.getString("name"); // "my_package"
```

### Large Hex Numbers

Fingerprints and other large hex values:

```zig
const source = ".{ .fingerprint = 0xee480fa30d50cbf6 }";
var doc = try zon.parse(allocator, source);
defer doc.deinit();

const fp = doc.getInt("fingerprint").?;
std.debug.print("Fingerprint: 0x{x}\n", .{@as(u64, @bitCast(fp))});
```

### Arrays

```zig
const source =
    \\.{
    \\    .paths = .{
    \\        "build.zig",
    \\        "src",
    \\        "README.md",
    \\    },
    \\}
;

var doc = try zon.parse(allocator, source);
defer doc.deinit();

// Get array length
const len = doc.arrayLen("paths"); // 3

// Get elements
const first = doc.getArrayString("paths", 0); // "build.zig"

// Iterate
var i: usize = 0;
while (doc.getArrayString("paths", i)) |path| : (i += 1) {
    std.debug.print("{s}\n", .{path});
}
```

## Error Handling

```zig
const doc = zon.open(allocator, "config.zon") catch |err| switch (err) {
    error.FileNotFound => {
        std.debug.print("Config file not found\n", .{});
        return;
    },
    error.UnexpectedToken => {
        std.debug.print("Invalid ZON syntax\n", .{});
        return;
    },
    else => return err,
};
defer doc.deinit();
```

## Reading build.zig.zon

```zig
const std = @import("std");
const zon = @import("zon");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    zon.disableUpdateCheck();

    var doc = try zon.open(allocator, "build.zig.zon");
    defer doc.deinit();

    // Read package info
    const name = doc.getString("name") orelse "unknown";
    const version = doc.getString("version") orelse "0.0.0";
    const min_zig = doc.getString("minimum_zig_version");

    std.debug.print("Package: {s} v{s}\n", .{name, version});
    if (min_zig) |v| {
        std.debug.print("Minimum Zig: {s}\n", .{v});
    }

    // Read paths
    if (doc.arrayLen("paths")) |len| {
        std.debug.print("Paths ({d}):\n", .{len});
        var i: usize = 0;
        while (doc.getArrayString("paths", i)) |path| : (i += 1) {
            std.debug.print("  - {s}\n", .{path});
        }
    }
}
```
