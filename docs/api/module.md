# Module Functions

The main `zon` module provides top-level functions for working with ZON documents and files.

## Creating Documents

### create

Creates a new, empty ZON document.

```zig
var doc = zon.create(allocator);
defer doc.deinit();
```

### open

Opens and parses an existing ZON file.

```zig
var doc = try zon.open(allocator, "config.zon");
defer doc.deinit();
```

**Errors:**

- `FileNotFound` - File doesn't exist
- `AccessDenied` - Permission denied
- `UnexpectedToken` - Invalid ZON syntax

### parse

Parses ZON content from a string.

```zig
const source =
    \\.{
    \\    .name = "myapp",
    \\}
;

var doc = try zon.parse(allocator, source);
defer doc.deinit();
```

**Errors:**

- `UnexpectedToken` - Invalid syntax
- `InvalidNumber` - Malformed number
- `InvalidString` - Malformed string
- `OutOfMemory` - Allocation failed

## File Utilities

### fileExists

Checks if a file exists.

```zig
if (zon.fileExists("config.zon")) {
    // File exists
}
```

### copyFile

Copies a file to a new location.

```zig
try zon.copyFile("config.zon", "config.zon.backup");
```

### renameFile

Renames or moves a file.

```zig
try zon.renameFile("old.zon", "new.zon");
```

### deleteFile

Deletes a file.

```zig
try zon.deleteFile("temp.zon");
```

## Update Checker

### disableUpdateCheck

Disables automatic update checking.

```zig
zon.disableUpdateCheck();
```

### enableUpdateCheck

Enables automatic update checking.

```zig
zon.enableUpdateCheck();
```

### isUpdateCheckEnabled

Returns whether update checking is enabled.

```zig
if (zon.isUpdateCheckEnabled()) {
    // Updates are enabled
}
```

### checkForUpdates

Manually checks for updates and prints notification if available.

```zig
zon.checkForUpdates(allocator);
```

## Version Information

### version

The current library version string.

```zig
const ver = zon.version; // "0.0.1"
```

## Exported Types

### Document

The main document type for all operations.

```zig
pub const Document = document.Document;
```

### Value

The core value type representing all ZON data types.

```zig
pub const Value = @import("value.zig").Value;
```

## Complete Example

```zig
const std = @import("std");
const zon = @import("zon");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Disable update checking for production
    zon.disableUpdateCheck();

    // Check if config exists
    if (zon.fileExists("config.zon")) {
        // Open existing
        var doc = try zon.open(allocator, "config.zon");
        defer doc.deinit();

        std.debug.print("Config: {s}\n", .{doc.getString("name") orelse "unknown"});
    } else {
        // Create new
        var doc = zon.create(allocator);
        defer doc.deinit();

        try doc.setString("name", "myapp");
        try doc.setString("version", "1.0.0");

        try doc.saveAs("config.zon");
        std.debug.print("Created config.zon\n", .{});
    }

    // Show library version
    std.debug.print("zon.zig version: {s}\n", .{zon.version});
}
```
