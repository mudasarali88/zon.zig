//! Update Checker
//!
//! Provides optional background checking for library updates.
//! Compares the current version against the latest GitHub release.
//! This feature can be disabled via configuration.

const std = @import("std");
const version = @import("version.zig");

/// Version comparison result.
pub const VersionRelation = enum {
    local_newer,
    remote_newer,
    equal,
    unknown,
};

/// Update check result.
pub const UpdateInfo = struct {
    available: bool,
    current_version: []const u8,
    latest_version: ?[]const u8,
    download_url: ?[]const u8,

    pub fn deinit(self: *UpdateInfo, allocator: std.mem.Allocator) void {
        if (self.latest_version) |v| allocator.free(v);
        if (self.download_url) |u| allocator.free(u);
    }
};

/// Configuration for update checking.
pub const UpdateConfig = struct {
    /// Enable or disable update checking.
    enabled: bool = true,
    /// Timeout for HTTP requests in milliseconds.
    timeout_ms: u64 = 5000,
    /// Custom user agent string.
    user_agent: []const u8 = "zon.zig-update-checker",
};

/// Global configuration (can be modified before first use).
pub var config: UpdateConfig = .{};

/// Disable update checking globally.
pub fn disableUpdateCheck() void {
    config.enabled = false;
}

/// Enable update checking globally.
pub fn enableUpdateCheck() void {
    config.enabled = true;
}

/// Check if update checking is enabled.
pub fn isUpdateCheckEnabled() bool {
    return config.enabled;
}

/// Check for updates from GitHub.
pub fn checkForUpdates(allocator: std.mem.Allocator) !UpdateInfo {
    if (!config.enabled) {
        return UpdateInfo{
            .available = false,
            .current_version = version.version,
            .latest_version = null,
            .download_url = null,
        };
    }

    var http_client = std.http.Client{ .allocator = allocator };
    defer http_client.deinit();

    const uri = try std.Uri.parse("https://api.github.com/repos/muhammad-fiaz/zon.zig/releases/latest");

    var server_header_buffer: [16 * 1024]u8 = undefined;
    var req = try http_client.open(.GET, uri, .{
        .extra_headers = &.{
            .{ .name = "User-Agent", .value = config.user_agent },
            .{ .name = "Accept", .value = "application/vnd.github.v3+json" },
        },
        .server_header_buffer = &server_header_buffer,
    });
    defer req.deinit();

    try req.send();
    try req.wait();

    if (req.status != .ok) {
        return UpdateInfo{
            .available = false,
            .current_version = version.version,
            .latest_version = null,
            .download_url = null,
        };
    }

    var body_buffer: std.ArrayListUnmanaged(u8) = .empty;
    defer body_buffer.deinit(allocator);

    var buf: [4096]u8 = undefined;
    while (true) {
        const n = try req.reader().read(&buf);
        if (n == 0) break;
        try body_buffer.appendSlice(allocator, buf[0..n]);
        if (body_buffer.items.len > 1 * 1024 * 1024) return error.StreamTooLong;
    }

    const parsed = try std.json.parseFromSlice(struct {
        tag_name: []const u8,
        html_url: []const u8,
    }, allocator, body_buffer.items, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();

    const latest = parseVersionTag(parsed.value.tag_name);
    const rel = compareVersions(latest);

    return UpdateInfo{
        .available = rel == .remote_newer,
        .current_version = version.version,
        .latest_version = try allocator.dupe(u8, latest),
        .download_url = try allocator.dupe(u8, parsed.value.html_url),
    };
}

/// Check for updates and print notification if available.
pub fn checkAndNotify(allocator: std.mem.Allocator) void {
    if (!config.enabled) return;

    const info = checkForUpdates(allocator) catch return;
    defer {
        var mutable_info = info;
        mutable_info.deinit(allocator);
    }

    if (info.available) {
        if (info.latest_version) |latest| {
            std.debug.print(
                "\n[zon.zig] Update available: {s} -> {s}\n" ++
                    "Download: https://github.com/muhammad-fiaz/zon.zig/releases/latest\n\n",
                .{ info.current_version, latest },
            );
        }
    }
}

/// Compare a version string against the current library version.
pub fn compareVersions(remote_version: []const u8) VersionRelation {
    const local = version.semanticVersion();
    const remote = std.SemanticVersion.parse(remote_version) catch return .unknown;

    if (local.major > remote.major) return .local_newer;
    if (local.major < remote.major) return .remote_newer;

    if (local.minor > remote.minor) return .local_newer;
    if (local.minor < remote.minor) return .remote_newer;

    if (local.patch > remote.patch) return .local_newer;
    if (local.patch < remote.patch) return .remote_newer;

    return .equal;
}

/// Get the current library version.
pub fn getCurrentVersion() []const u8 {
    return version.version;
}

/// Parse a version tag (e.g., "v1.2.3") to version string.
pub fn parseVersionTag(tag: []const u8) []const u8 {
    if (tag.len > 0 and tag[0] == 'v') {
        return tag[1..];
    }
    return tag;
}

/// Format update notification message.
pub fn formatUpdateMessage(
    allocator: std.mem.Allocator,
    current: []const u8,
    latest: []const u8,
) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "Update available: {s} -> {s}\n" ++
            "Download: https://github.com/muhammad-fiaz/zon.zig/releases/latest",
        .{ current, latest },
    );
}

test "version comparison - equal" {
    const result = compareVersions(version.version);
    try std.testing.expect(result == .equal);
}

test "version comparison - remote newer" {
    const result = compareVersions("1.0.0");
    try std.testing.expect(result == .remote_newer);
}

test "version comparison - local newer" {
    const result = compareVersions("0.0.0");
    try std.testing.expect(result == .local_newer);
}

test "current version" {
    const ver = getCurrentVersion();
    try std.testing.expectEqualStrings("0.0.1", ver);
}

test "version tag parsing" {
    try std.testing.expectEqualStrings("1.2.3", parseVersionTag("v1.2.3"));
    try std.testing.expectEqualStrings("1.2.3", parseVersionTag("1.2.3"));
}

test "disable update check" {
    disableUpdateCheck();
    try std.testing.expect(!isUpdateCheckEnabled());
    enableUpdateCheck();
    try std.testing.expect(isUpdateCheckEnabled());
}
