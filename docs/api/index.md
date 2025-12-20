# API Overview

zon.zig provides a simple, direct API for reading and writing ZON files.

## Module Structure

```
zon.zig
├── zon          # Main module with public functions
├── Document     # Document struct for all operations
├── Value        # Core value types
├── version      # Library version string
└── update_checker # Optional update notifications
```

## Quick Reference

### Module Functions

```zig
const zon = @import("zon");

// Create/Open/Parse
var doc = zon.create(allocator);         // New empty document
var doc = try zon.open(allocator, path); // Open file
var doc = try zon.parse(allocator, src); // Parse string

// File utilities
const exists = zon.fileExists(path);
try zon.copyFile(src, dst);
try zon.renameFile(old, new);
try zon.deleteFile(path);

// Update checker
zon.disableUpdateCheck();
zon.enableUpdateCheck();
zon.checkForUpdates(allocator);

// Version
const ver = zon.version; // "0.0.1"
```

### Document Methods

```zig
// Getters
doc.getString("path")     // ?[]const u8
doc.getInt("path")        // ?i64
doc.getFloat("path")      // ?f64
doc.getBool("path")       // ?bool
doc.exists("path")        // bool
doc.isNull("path")        // bool
doc.getType("path")       // ?[]const u8
doc.getValue("path")      // ?*const Value
doc.isEmpty()             // bool

// Setters
try doc.setString("path", "value");
try doc.setInt("path", 123);
try doc.setFloat("path", 3.14);
try doc.setBool("path", true);
try doc.setNull("path");
try doc.setObject("path");
try doc.setArray("path");
try doc.setValue("path", value);

// Modification
doc.delete("path");       // bool
doc.clear();
doc.count();              // usize
try doc.keys();           // [][]const u8

// Arrays
doc.arrayLen("path");                    // ?usize
doc.getArrayString("path", index);       // ?[]const u8
doc.getArrayInt("path", index);          // ?i64
doc.getArrayBool("path", index);         // ?bool
try doc.appendToArray("path", "value");
try doc.appendIntToArray("path", 123);
try doc.appendFloatToArray("path", 3.14);
try doc.appendBoolToArray("path", true);

// Find & Replace
try doc.findString("needle");            // [][]const u8
try doc.findExact("needle");             // [][]const u8
try doc.replaceAll("find", "replace");   // usize
try doc.replaceFirst("find", "replace"); // bool
try doc.replaceLast("find", "replace");  // bool

// Merge & Clone
try doc.merge(&other);
var copy = try doc.clone();
try doc.diff(&other);    // [][]const u8

// Output
try doc.save();
try doc.saveAs("path");
try doc.toString();           // []u8 (4-space)
try doc.toCompactString();    // []u8 (no indent)
try doc.toPrettyString(2);    // []u8 (custom)

// Access
doc.getObject("path");   // ?*Value.Object
doc.getArray("path");    // ?*Value.Array

// Cleanup
doc.deinit();
```

### Value Types

```zig
const Value = union(enum) {
    null_val,
    bool_val: bool,
    number: Number,
    string: []const u8,
    object: Object,
    array: Array,
};

const Number = union(enum) {
    int: i64,
    float: f64,
};
```

## Error Handling

- **Getters** return `null` for missing paths or type mismatches
- **Setters** return `!void` (can error on OutOfMemory)
- **Parse** returns `ParseError` on invalid syntax
- **File ops** return standard I/O errors

## Memory Management

All Documents must be deinitialized:

```zig
var doc = zon.create(allocator);
defer doc.deinit(); // Always cleanup
```

Returned strings from `toString()`, `keys()`, etc. must be freed:

```zig
const output = try doc.toString();
defer allocator.free(output);
```
