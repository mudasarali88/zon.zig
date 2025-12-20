# Writing ZON Files

Learn how to create and save ZON files with zon.zig.

## Creating a Document

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
try doc.setNull("optional");
```

### Nested Paths

Intermediate objects are created automatically:

```zig
try doc.setString("config.server.host", "localhost");
try doc.setInt("config.server.port", 8080);
try doc.setString("config.database.url", "postgres://localhost/myapp");
```

### Objects and Arrays

```zig
// Create empty object
try doc.setObject("metadata");

// Create empty array
try doc.setArray("tags");

// Append to array
try doc.appendToArray("tags", "stable");
try doc.appendToArray("tags", "v1.0");
try doc.appendIntToArray("numbers", 42);
```

## Saving Documents

### Save to File

```zig
// Save to a specific path
try doc.saveAs("config.zon");

// Save to original path (only if opened with zon.open)
try doc.save();
```

### Get as String

```zig
// Default formatting (4-space indent)
const output = try doc.toString();
defer allocator.free(output);
std.debug.print("{s}\n", .{output});

// Custom indentation
const pretty = try doc.toPrettyString(2);
defer allocator.free(pretty);

// Compact (no indentation)
const compact = try doc.toCompactString();
defer allocator.free(compact);
```

## Modifying Documents

### Update Values

```zig
try doc.setString("version", "2.0.0");  // Overwrites existing
try doc.setInt("port", 9000);
```

### Delete Values

```zig
const deleted = doc.delete("private");
if (deleted) {
    std.debug.print("Key deleted\n", .{});
}
```

### Clear All Data

```zig
doc.clear();  // Resets to empty object
```

## File Operations

### Check if File Exists

```zig
if (zon.fileExists("config.zon")) {
    std.debug.print("Config exists\n", .{});
}
```

### Copy File

```zig
try zon.copyFile("config.zon", "config.zon.backup");
```

### Rename File

```zig
try zon.renameFile("old.zon", "new.zon");
```

### Delete File

```zig
try zon.deleteFile("temp.zon");
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

    // Package info
    try doc.setString("name", "myapp");
    try doc.setString("version", "1.0.0");

    // Configuration
    try doc.setString("server.host", "0.0.0.0");
    try doc.setInt("server.port", 8080);
    try doc.setBool("server.ssl", false);

    try doc.setString("database.host", "localhost");
    try doc.setInt("database.port", 5432);
    try doc.setString("database.name", "myapp");

    // Create paths array
    try doc.setArray("paths");
    try doc.appendToArray("paths", "build.zig");
    try doc.appendToArray("paths", "src");
    try doc.appendToArray("paths", "README.md");

    // Output
    const output = try doc.toString();
    defer allocator.free(output);
    std.debug.print("{s}\n", .{output});

    // Save
    try doc.saveAs("config.zon");
    std.debug.print("Saved to config.zon\n", .{});

    // Create backup
    try zon.copyFile("config.zon", "config.zon.backup");
    std.debug.print("Backup created\n", .{});
}
```

Output:

```zig
.{
    .database = .{
        .host = "localhost",
        .name = "myapp",
        .port = 5432,
    },
    .name = "myapp",
    .paths = .{
        "build.zig",
        "src",
        "README.md",
    },
    .server = .{
        .host = "0.0.0.0",
        .port = 8080,
        .ssl = false,
    },
    .version = "1.0.0",
}
```
