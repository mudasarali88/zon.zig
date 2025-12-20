# Basic Usage

This guide covers the core operations in zon.zig.

## Creating a Document

Create a new, empty ZON document:

```zig
const zon = @import("zon");

var doc = zon.create(allocator);
defer doc.deinit();
```

## Setting Values

### Basic Types

```zig
try doc.setString("name", "myapp");
try doc.setBool("private", true);
try doc.setInt("port", 8080);
try doc.setFloat("timeout", 30.5);
try doc.setNull("optional_field");
```

### Nested Paths

Use dot notation to set nested values. Intermediate objects are created automatically:

```zig
// Creates: .{ .config = .{ .server = .{ .host = "localhost" } } }
try doc.setString("config.server.host", "localhost");
try doc.setInt("config.server.port", 8080);
```

### Objects and Arrays

```zig
// Create empty object
try doc.setObject("metadata");

// Create empty array
try doc.setArray("tags");
```

## Getting Values

All getters return optional values - `null` for missing paths or type mismatches:

```zig
const name = doc.getString("name");           // ?[]const u8
const port = doc.getInt("port");              // ?i64
const timeout = doc.getFloat("timeout");      // ?f64
const private = doc.getBool("private");       // ?bool

// Use with orelse for defaults
const host = doc.getString("host") orelse "localhost";
const max_conn = doc.getInt("max_connections") orelse 100;
```

### Check Value Properties

```zig
// Check if path exists
if (doc.exists("config.port")) {
    // Path exists
}

// Check if value is null
if (doc.isNull("optional_field")) {
    // Value is explicitly null
}

// Get value type
const type_name = doc.getType("name"); // "string", "int", "bool", etc.
```

## Deleting Values

```zig
// Delete a key - returns true if existed
const deleted = doc.delete("private");
if (deleted) {
    std.debug.print("Key was deleted\n", .{});
}

// Clear all data
doc.clear();
```

## Document Information

```zig
// Count root keys
const key_count = doc.count();

// Get all root keys
const all_keys = try doc.keys();
defer allocator.free(all_keys);
for (all_keys) |key| {
    std.debug.print("Key: {s}\n", .{key});
}
```

## Saving

### Save to File

```zig
// Save to a new file
try doc.saveAs("config.zon");

// Save to original file (only works if opened with zon.open)
try doc.save();
```

### Get as String

```zig
// Default formatting (4-space indent)
const output = try doc.toString();
defer allocator.free(output);

// Custom indentation
const pretty = try doc.toPrettyString(2);
defer allocator.free(pretty);

// Compact (minimal whitespace)
const compact = try doc.toCompactString();
defer allocator.free(compact);
```

## Complete Example

```zig
const std = @import("std");
const zon = @import("zon");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    zon.disableUpdateCheck();

    // Create document
    var doc = zon.create(allocator);
    defer doc.deinit();

    // Set values
    try doc.setString("name", "myapp");
    try doc.setString("version", "1.0.0");
    try doc.setBool("private", true);
    try doc.setInt("port", 8080);

    // Set nested values
    try doc.setString("database.host", "localhost");
    try doc.setInt("database.port", 5432);
    try doc.setString("database.name", "myapp");

    // Read values
    std.debug.print("App: {s} v{s}\n", .{
        doc.getString("name").?,
        doc.getString("version").?
    });
    std.debug.print("Database: {s}:{d}/{s}\n", .{
        doc.getString("database.host").?,
        doc.getInt("database.port").?,
        doc.getString("database.name").?
    });

    // Check existence
    if (doc.exists("private")) {
        std.debug.print("Private: {}\n", .{doc.getBool("private").?});
    }

    // Delete and verify
    _ = doc.delete("private");
    std.debug.print("Private after delete: {?}\n", .{doc.getBool("private")});

    // Get output
    const output = try doc.toString();
    defer allocator.free(output);
    std.debug.print("\nGenerated ZON:\n{s}\n", .{output});

    // Save
    try doc.saveAs("config.zon");
}
```
