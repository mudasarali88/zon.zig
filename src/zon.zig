//! zon.zig - A Zig library for reading and writing ZON files.
//!
//! Repository: https://github.com/muhammad-fiaz/zon.zig

const std = @import("std");
const Allocator = std.mem.Allocator;
const document = @import("document.zig");
pub const version_info = @import("version.zig");
pub const update_checker = @import("update_checker.zig");
pub const Value = @import("value.zig").Value;

pub const Document = document.Document;
pub const version = version_info.version;

/// Disables update checking.
pub fn disableUpdateCheck() void {
    update_checker.disableUpdateCheck();
}

/// Enables update checking.
pub fn enableUpdateCheck() void {
    update_checker.enableUpdateCheck();
}

/// Returns true if update checking is enabled.
pub fn isUpdateCheckEnabled() bool {
    return update_checker.isUpdateCheckEnabled();
}

/// Checks for updates and prints notification if available.
pub fn checkForUpdates(allocator: Allocator) void {
    update_checker.checkAndNotify(allocator);
}

/// Opens an existing ZON file.
pub fn open(allocator: Allocator, file_path: []const u8) !Document {
    return Document.initFromFile(allocator, file_path);
}

/// Creates a new empty document.
pub fn create(allocator: Allocator) Document {
    return Document.initEmpty(allocator);
}

/// Parses ZON from a string.
pub fn parse(allocator: Allocator, source: []const u8) !Document {
    return Document.initFromSource(allocator, source);
}

/// Deletes a file.
pub fn deleteFile(file_path: []const u8) !void {
    try std.fs.cwd().deleteFile(file_path);
}

/// Returns true if the file exists.
pub fn fileExists(file_path: []const u8) bool {
    std.fs.cwd().access(file_path, .{}) catch return false;
    return true;
}

/// Copies a file.
pub fn copyFile(source_path: []const u8, dest_path: []const u8) !void {
    try std.fs.cwd().copyFile(source_path, std.fs.cwd(), dest_path, .{});
}

/// Renames a file.
pub fn renameFile(old_path: []const u8, new_path: []const u8) !void {
    try std.fs.cwd().rename(old_path, new_path);
}

test "create and set values" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try doc.setString("name", "myapp");
    try doc.setBool("private", true);
    try doc.setInt("version", 1);
    try doc.setFloat("score", 3.14);

    try std.testing.expectEqualStrings("myapp", doc.getString("name").?);
    try std.testing.expectEqual(true, doc.getBool("private").?);
    try std.testing.expectEqual(@as(i64, 1), doc.getInt("version").?);
    try std.testing.expectApproxEqAbs(@as(f64, 3.14), doc.getFloat("score").?, 0.001);
}

test "nested paths" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try doc.setString("dependencies.foo.path", "../foo");
    try doc.setString("dependencies.foo.version", "1.0.0");
    try doc.setString("dependencies.bar.path", "../bar");

    try std.testing.expectEqualStrings("../foo", doc.getString("dependencies.foo.path").?);
    try std.testing.expectEqualStrings("1.0.0", doc.getString("dependencies.foo.version").?);
    try std.testing.expectEqualStrings("../bar", doc.getString("dependencies.bar.path").?);
}

test "delete values" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try doc.setString("name", "myapp");
    try doc.setBool("private", true);

    try std.testing.expect(doc.getString("name") != null);
    try std.testing.expect(doc.delete("name"));
    try std.testing.expect(doc.getString("name") == null);
}

test "parse zon source" {
    const allocator = std.testing.allocator;

    const source =
        \\.{
        \\    .name = "test",
        \\    .version = 123,
        \\    .enabled = true,
        \\}
    ;

    var doc = try parse(allocator, source);
    defer doc.deinit();

    try std.testing.expectEqualStrings("test", doc.getString("name").?);
    try std.testing.expectEqual(@as(i64, 123), doc.getInt("version").?);
    try std.testing.expectEqual(true, doc.getBool("enabled").?);
}

test "parse build.zig.zon format" {
    const allocator = std.testing.allocator;

    const source =
        \\.{
        \\    .name = .zon,
        \\    .version = "0.0.1",
        \\    .fingerprint = 0xee480fa30d50cbf6,
        \\    .minimum_zig_version = "0.15.0",
        \\    .paths = .{
        \\        "build.zig",
        \\        "build.zig.zon",
        \\        "src",
        \\    },
        \\}
    ;

    var doc = try parse(allocator, source);
    defer doc.deinit();

    try std.testing.expectEqualStrings("zon", doc.getString("name").?);
    try std.testing.expectEqualStrings("0.0.1", doc.getString("version").?);
    try std.testing.expect(doc.getInt("fingerprint") != null);
    try std.testing.expectEqual(@as(usize, 3), doc.arrayLen("paths").?);
    try std.testing.expectEqualStrings("build.zig", doc.getArrayString("paths", 0).?);
}

test "missing paths return null" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try std.testing.expect(doc.getString("nonexistent") == null);
    try std.testing.expect(doc.getBool("nonexistent") == null);
    try std.testing.expect(doc.getInt("nonexistent") == null);
}

test "type mismatch returns null" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try doc.setString("name", "test");

    try std.testing.expect(doc.getString("name") != null);
    try std.testing.expect(doc.getBool("name") == null);
    try std.testing.expect(doc.getInt("name") == null);
}

test "stringify document" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try doc.setString("name", "myapp");
    try doc.setBool("private", true);

    const output = try doc.toString();
    defer allocator.free(output);

    try std.testing.expect(std.mem.indexOf(u8, output, ".name") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\"myapp\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, ".private") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "true") != null);
}

test "version info" {
    try std.testing.expectEqualStrings("0.0.1", version);
}

test "find and replace" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try doc.setString("a", "hello");
    try doc.setString("b", "hello");
    try doc.setString("c", "world");

    const count_val = try doc.replaceAll("hello", "goodbye");
    try std.testing.expectEqual(@as(usize, 2), count_val);

    try std.testing.expectEqualStrings("goodbye", doc.getString("a").?);
    try std.testing.expectEqualStrings("goodbye", doc.getString("b").?);
    try std.testing.expectEqualStrings("world", doc.getString("c").?);
}

test "find string" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try doc.setString("name", "hello world");
    try doc.setString("other", "hello there");
    try doc.setString("different", "goodbye");

    const results = try doc.findString("hello");
    defer {
        for (results) |r| allocator.free(r);
        allocator.free(results);
    }

    try std.testing.expectEqual(@as(usize, 2), results.len);
}

test "pretty print" {
    const allocator = std.testing.allocator;

    var doc = create(allocator);
    defer doc.deinit();

    try doc.setString("name", "myapp");

    const output2 = try doc.toPrettyString(2);
    defer allocator.free(output2);
    try std.testing.expect(std.mem.indexOf(u8, output2, "  .name") != null);

    const output4 = try doc.toPrettyString(4);
    defer allocator.free(output4);
    try std.testing.expect(std.mem.indexOf(u8, output4, "    .name") != null);
}
