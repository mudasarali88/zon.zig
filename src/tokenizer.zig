//! Tokenizer - Lexical analysis for ZON source code.
//!
//! This module provides a tokenizer that converts ZON source text into a stream of tokens.
//! It handles all ZON lexical elements including identifiers, strings, numbers, and punctuation.
//!
//! ## Supported Tokens
//!
//! | Token | Example |
//! |-------|---------|
//! | `.` | Dot |
//! | `{` `}` | Braces |
//! | `[` `]` | Brackets |
//! | `,` | Comma |
//! | `=` | Equals |
//! | `:` | Colon |
//! | `@` | At sign |
//! | `"..."` | String literal |
//! | `'...'` | Character literal |
//! | `123`, `0xFF` | Number literal |
//! | `true`, `false`, `null` | Keywords |
//! | `name` | Identifier |
//!

const std = @import("std");

/// Represents a single token from the source.
pub const Token = struct {
    /// The type of token.
    tag: Tag,
    /// Start position in the source.
    start: usize,
    /// End position in the source (exclusive).
    end: usize,

    /// Token types.
    pub const Tag = enum {
        /// `.`
        dot,
        /// `{`
        l_brace,
        /// `}`
        r_brace,
        /// `[`
        l_bracket,
        /// `]`
        r_bracket,
        /// `,`
        comma,
        /// `=`
        equals,
        /// `:`
        colon,
        /// An identifier (variable name, key name)
        identifier,
        /// A string literal `"..."`
        string_literal,
        /// A character literal `'...'`
        char_literal,
        /// A number literal (integer or float)
        number_literal,
        /// The `true` keyword
        keyword_true,
        /// The `false` keyword
        keyword_false,
        /// The `null` keyword
        keyword_null,
        /// `@`
        at_sign,
        /// End of file
        eof,
        /// Invalid token
        invalid,
    };
};

/// Tokenizes ZON source code.
///
/// Create with `init()`, then call `next()` repeatedly to get tokens.
pub const Tokenizer = struct {
    /// The source being tokenized.
    source: []const u8,
    /// Current position in the source.
    index: usize,

    /// Creates a new tokenizer for the given source.
    pub fn init(source: []const u8) Tokenizer {
        return .{
            .source = source,
            .index = 0,
        };
    }

    /// Returns the next token from the source.
    ///
    /// Returns `.eof` when the end of the source is reached.
    pub fn next(self: *Tokenizer) Token {
        self.skipWhitespaceAndComments();

        const start = self.index;

        if (self.index >= self.source.len) {
            return .{ .tag = .eof, .start = start, .end = start };
        }

        const c = self.source[self.index];

        switch (c) {
            '.' => {
                self.index += 1;
                return .{ .tag = .dot, .start = start, .end = self.index };
            },
            '{' => {
                self.index += 1;
                return .{ .tag = .l_brace, .start = start, .end = self.index };
            },
            '}' => {
                self.index += 1;
                return .{ .tag = .r_brace, .start = start, .end = self.index };
            },
            '[' => {
                self.index += 1;
                return .{ .tag = .l_bracket, .start = start, .end = self.index };
            },
            ']' => {
                self.index += 1;
                return .{ .tag = .r_bracket, .start = start, .end = self.index };
            },
            ',' => {
                self.index += 1;
                return .{ .tag = .comma, .start = start, .end = self.index };
            },
            '=' => {
                self.index += 1;
                return .{ .tag = .equals, .start = start, .end = self.index };
            },
            ':' => {
                self.index += 1;
                return .{ .tag = .colon, .start = start, .end = self.index };
            },
            '@' => {
                self.index += 1;
                return .{ .tag = .at_sign, .start = start, .end = self.index };
            },
            '"' => return self.scanString(),
            '\'' => return self.scanChar(),
            '-', '+', '0'...'9' => return self.scanNumber(),
            'a'...'z', 'A'...'Z', '_' => return self.scanIdentifier(),
            else => {
                self.index += 1;
                return .{ .tag = .invalid, .start = start, .end = self.index };
            },
        }
    }

    /// Skips whitespace and line comments.
    fn skipWhitespaceAndComments(self: *Tokenizer) void {
        while (self.index < self.source.len) {
            const c = self.source[self.index];
            switch (c) {
                ' ', '\t', '\n', '\r' => self.index += 1,
                '/' => {
                    if (self.index + 1 < self.source.len and self.source[self.index + 1] == '/') {
                        self.index += 2;
                        while (self.index < self.source.len and self.source[self.index] != '\n') {
                            self.index += 1;
                        }
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }

    /// Scans a string literal.
    fn scanString(self: *Tokenizer) Token {
        const start = self.index;
        self.index += 1;

        while (self.index < self.source.len) {
            const c = self.source[self.index];
            if (c == '"') {
                self.index += 1;
                return .{ .tag = .string_literal, .start = start, .end = self.index };
            } else if (c == '\\') {
                self.index += 2;
            } else {
                self.index += 1;
            }
        }

        return .{ .tag = .invalid, .start = start, .end = self.index };
    }

    /// Scans a character literal.
    fn scanChar(self: *Tokenizer) Token {
        const start = self.index;
        self.index += 1;

        while (self.index < self.source.len) {
            const c = self.source[self.index];
            if (c == '\'') {
                self.index += 1;
                return .{ .tag = .char_literal, .start = start, .end = self.index };
            } else if (c == '\\') {
                self.index += 2;
            } else {
                self.index += 1;
            }
        }

        return .{ .tag = .invalid, .start = start, .end = self.index };
    }

    /// Scans a number literal.
    ///
    /// Supports decimal, hexadecimal (0x), octal (0o), binary (0b), and floats.
    fn scanNumber(self: *Tokenizer) Token {
        const start = self.index;

        if (self.source[self.index] == '-' or self.source[self.index] == '+') {
            self.index += 1;
        }

        if (self.index < self.source.len and self.source[self.index] == '0') {
            self.index += 1;
            if (self.index < self.source.len) {
                switch (self.source[self.index]) {
                    'x', 'X' => {
                        self.index += 1;
                        while (self.index < self.source.len and isHexDigit(self.source[self.index])) {
                            self.index += 1;
                        }
                        return .{ .tag = .number_literal, .start = start, .end = self.index };
                    },
                    'o', 'O' => {
                        self.index += 1;
                        while (self.index < self.source.len and isOctalDigit(self.source[self.index])) {
                            self.index += 1;
                        }
                        return .{ .tag = .number_literal, .start = start, .end = self.index };
                    },
                    'b', 'B' => {
                        self.index += 1;
                        while (self.index < self.source.len and isBinaryDigit(self.source[self.index])) {
                            self.index += 1;
                        }
                        return .{ .tag = .number_literal, .start = start, .end = self.index };
                    },
                    else => {},
                }
            }
        }

        while (self.index < self.source.len and isDigit(self.source[self.index])) {
            self.index += 1;
        }

        if (self.index < self.source.len and self.source[self.index] == '.') {
            if (self.index + 1 < self.source.len and isDigit(self.source[self.index + 1])) {
                self.index += 1;
                while (self.index < self.source.len and isDigit(self.source[self.index])) {
                    self.index += 1;
                }
            }
        }

        if (self.index < self.source.len and (self.source[self.index] == 'e' or self.source[self.index] == 'E')) {
            self.index += 1;
            if (self.index < self.source.len and (self.source[self.index] == '+' or self.source[self.index] == '-')) {
                self.index += 1;
            }
            while (self.index < self.source.len and isDigit(self.source[self.index])) {
                self.index += 1;
            }
        }

        return .{ .tag = .number_literal, .start = start, .end = self.index };
    }

    /// Scans an identifier or keyword.
    fn scanIdentifier(self: *Tokenizer) Token {
        const start = self.index;

        while (self.index < self.source.len) {
            const c = self.source[self.index];
            if (isAlphaNumeric(c) or c == '_') {
                self.index += 1;
            } else {
                break;
            }
        }

        const ident = self.source[start..self.index];

        const tag: Token.Tag = if (std.mem.eql(u8, ident, "true"))
            .keyword_true
        else if (std.mem.eql(u8, ident, "false"))
            .keyword_false
        else if (std.mem.eql(u8, ident, "null"))
            .keyword_null
        else
            .identifier;

        return .{ .tag = tag, .start = start, .end = self.index };
    }

    /// Returns the source text for a token.
    pub fn slice(self: *const Tokenizer, token: Token) []const u8 {
        return self.source[token.start..token.end];
    }
};

// ============================================================================
// Character Classification Helpers
// ============================================================================

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isHexDigit(c: u8) bool {
    return isDigit(c) or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
}

fn isOctalDigit(c: u8) bool {
    return c >= '0' and c <= '7';
}

fn isBinaryDigit(c: u8) bool {
    return c == '0' or c == '1';
}

fn isAlphaNumeric(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_';
}
