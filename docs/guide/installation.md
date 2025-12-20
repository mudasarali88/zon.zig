# Installation

This guide covers all methods for installing zon.zig in your Zig project.

## Supported Platforms

zon.zig supports a wide range of platforms:

| Platform         | 32-bit               | 64-bit                      | ARM        |
| ---------------- | -------------------- | --------------------------- | ---------- |
| **Windows**      | ✅ x86               | ✅ x86_64                   | -          |
| **Linux**        | ✅ x86               | ✅ x86_64                   | ✅ aarch64 |
| **macOS**        | ✅ x86               | ✅ x86_64                   | ✅ aarch64 |
| **Freestanding** | ✅ x86, arm, riscv32 | ✅ x86_64, aarch64, riscv64 | ✅         |

## Method 1: Zig Fetch (Recommended)

The simplest way to add zon.zig:

```bash
zig fetch --save https://github.com/muhammad-fiaz/zon.zig/archive/refs/tags/v0.0.1.tar.gz
```

This command:

1. Downloads the package
2. Calculates the hash
3. Updates your `build.zig.zon` automatically

## Method 2: Manual Configuration

Add the dependency to your `build.zig.zon`:

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .dependencies = .{
        .zon = .{
            .url = "https://github.com/muhammad-fiaz/zon.zig/archive/refs/tags/v0.0.1.tar.gz",
            .hash = "...", // Get hash from zig fetch
        },
    },
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

To get the hash:

```bash
zig fetch https://github.com/muhammad-fiaz/zon.zig/archive/refs/tags/v0.0.1.tar.gz
```

## Configure build.zig

After adding the dependency, update your `build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add zon.zig dependency
    const zon_dep = b.dependency("zon", .{
        .target = target,
        .optimize = optimize,
    });

    // Create executable
    const exe = b.addExecutable(.{
        .name = "my_app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zon", .module = zon_dep.module("zon") },
            },
        }),
    });

    b.installArtifact(exe);
}
```

## Verify Installation

Create a simple test file:

```zig
const std = @import("std");
const zon = @import("zon");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Disable update checking for test
    zon.disableUpdateCheck();

    var doc = zon.create(gpa.allocator());
    defer doc.deinit();

    try doc.setString("test", "hello");
    std.debug.print("zon.zig v{s} is working!\n", .{zon.version});
}
```

Build and run:

```bash
zig build run
```

## Troubleshooting

### Hash Mismatch

If you get a hash mismatch error, regenerate the hash:

```bash
zig fetch --save https://github.com/muhammad-fiaz/zon.zig/archive/refs/tags/v0.0.1.tar.gz
```

### Module Not Found

Ensure you've added the import to your `build.zig`:

```zig
.imports = &.{
    .{ .name = "zon", .module = zon_dep.module("zon") },
},
```

### Version Compatibility

zon.zig requires Zig 0.15.0 or later. Check your version:

```bash
zig version
```
