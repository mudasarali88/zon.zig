# Getting Started

This guide will help you get started with zon.zig in just a few minutes.

## Prerequisites

- Zig 0.15.0 or later
- A Zig project with `build.zig` and `build.zig.zon`

## Installation

The easiest way to add zon.zig to your project:

```bash
zig fetch --save https://github.com/muhammad-fiaz/zon.zig/archive/refs/tags/v0.0.1.tar.gz
```

This automatically adds the dependency to your `build.zig.zon`.

Then update your `build.zig`:

```zig
const zon_dep = b.dependency("zon", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("zon", zon_dep.module("zon"));
```

## Your First ZON Document

Here's a complete example that creates, modifies, and saves a ZON file:

```zig
const std = @import("std");
const zon = @import("zon");

pub fn main() !void {
    // Setup allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Optional: Disable update checking
    zon.disableUpdateCheck();

    // Create a new document
    var doc = zon.create(allocator);
    defer doc.deinit();

    // Set some values
    try doc.setString("name", "myapp");
    try doc.setString("version", "1.0.0");
    try doc.setBool("private", true);
    try doc.setInt("port", 8080);

    // Set nested values (creates intermediate objects automatically)
    try doc.setString("dependencies.http.path", "../http");
    try doc.setString("dependencies.http.version", "0.1.0");

    // Read values back
    if (doc.getString("name")) |name| {
        std.debug.print("Name: {s}\n", .{name});
    }

    if (doc.getInt("port")) |port| {
        std.debug.print("Port: {d}\n", .{port});
    }

    // Save to file
    try doc.saveAs("config.zon");
    std.debug.print("Saved to config.zon\n", .{});
}
```

## Opening Existing Files

To read an existing ZON file:

```zig
var doc = try zon.open(allocator, "build.zig.zon");
defer doc.deinit();

const name = doc.getString("name");
const version = doc.getString("version");
```

## Update Checker

zon.zig includes an optional update checker. To disable it:

```zig
// Call before other operations
zon.disableUpdateCheck();
```

## Next Steps

- [Basic Usage](/guide/basic-usage) - Learn the core API
- [Reading Files](/guide/reading) - Read and parse ZON files
- [Writing Files](/guide/writing) - Create and save ZON files
- [API Reference](/api/) - Complete API documentation
