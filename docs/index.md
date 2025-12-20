---
layout: home

hero:
  name: "zon.zig"
  text: "ZON Library for Zig"
  tagline: A simple, direct library for reading and writing ZON (Zig Object Notation) files
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/muhammad-fiaz/zon.zig

features:
  - icon: 📖
    title: Simple API
    details: Clean open, get, set, delete, save interface that feels natural and intuitive.
  - icon: 🔗
    title: Path-Based Access
    details: Use dot notation like "dependencies.foo.path" to access nested values easily.
  - icon: 🏗️
    title: Auto-Create Objects
    details: Missing intermediate paths are created automatically when setting values.
  - icon: 🔒
    title: Type-Safe
    details: getString, getBool, getInt, getFloat with null returns for type mismatches.
  - icon: 🛡️
    title: No Panics
    details: Missing paths return null, type mismatches return null. Safe by default.
  - icon: ⚡
    title: High Performance
    details: Custom parser built on Zig standard library. No compiler internals.
  - icon: 🖥️
    title: Cross-Platform
    details: Supports Windows, Linux, macOS - both 32-bit and 64-bit architectures.
  - icon: 🔄
    title: Update Checker
    details: Optional auto-update checking that can be easily disabled.
---

## Quick Example

```zig
const std = @import("std");
const zon = @import("zon");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Optional: Disable update checking
    zon.disableUpdateCheck();

    // Create a new ZON document
    var doc = zon.create(allocator);
    defer doc.deinit();

    // Set values (nested paths auto-create objects)
    try doc.setString("name", "myapp");
    try doc.setString("dependencies.http.path", "../http");

    // Read values
    const name = doc.getString("name"); // "myapp"
    const path = doc.getString("dependencies.http.path"); // "../http"

    // Save to file
    try doc.saveAs("config.zon");
}
```

## Installation

```bash
zig fetch --save https://github.com/muhammad-fiaz/zon.zig/archive/refs/tags/v0.0.1.tar.gz
```

Then in your `build.zig`:

```zig
const zon_dep = b.dependency("zon", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("zon", zon_dep.module("zon"));
```
