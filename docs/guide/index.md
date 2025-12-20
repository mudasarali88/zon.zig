# What is zon.zig?

zon.zig is a simple, direct Zig library for reading and writing ZON (Zig Object Notation) files. It provides a clean, intuitive API for configuration file management and data serialization.

## Why zon.zig?

ZON is the native configuration format for Zig projects, used in `build.zig.zon` files. While Zig provides AST-based parsing through `std.zig.Ast`, this approach is complex and exposes internal compiler details.

zon.zig provides a simpler alternative:

- **Path-based access** - Use dot notation to navigate nested structures
- **Auto-creation** - Missing intermediate objects are created automatically
- **Type-safe getters** - Returns `null` for missing paths or type mismatches
- **No panics** - Safe by default, no unexpected crashes
- **Custom parser** - Does not depend on `std.zig.Ast` or compiler internals
- **Cross-platform** - Windows, Linux, macOS (32-bit and 64-bit)
- **Update checker** - Optional auto-update checking (can be disabled)

## Use Cases

- Reading and modifying `build.zig.zon` files
- Configuration file management
- Data serialization in ZON format
- Build system tooling

## Example

```zig
const zon = @import("zon");

// Disable update checking if desired
zon.disableUpdateCheck();

// Open existing file
var doc = try zon.open(allocator, "build.zig.zon");
defer doc.deinit();

// Read values
const name = doc.getString("name");
const version = doc.getString("version");

// Modify values
try doc.setString("version", "2.0.0");

// Save changes
try doc.save();
```

## Version

Current version: **0.0.1**

## Next Steps

- [Getting Started](/guide/getting-started) - Set up zon.zig in your project
- [Installation](/guide/installation) - Detailed installation instructions
- [API Reference](/api/) - Complete API documentation
