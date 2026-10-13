//! ## veritas
//!
//! "veritas" is a test assertion library inspired by
//! [AssertJ](https://assertj.github.io) while trying to adhere to Zig's overall
//! philosophy and [std.testing](https://ziglang.org/documentation/0.17.0/std/#std.testing)
//! taxonomy.
//!
//! ```zig
//! test {
//!     const actual = someFn(1234);
//!     try expectThat(actual).isNotNull();
//! }
//! ```

const std = @import("std");

/// Error set returned from expectation functions.
pub const Error = error{
    /// Catch-all error variant indicating an expectation function failed its
    /// assertion.
    ExpectationNotMet,
};

/// This function is intended to be used only in tests.
pub fn expectThat(actual: anytype) Expectations(@TypeOf(actual)) {
    return .{ .actual = actual };
}

test expectThat {
    {
        const actual: ?u0 = null;
        try expectThat(actual).isNull();
        // try std.testing.expectError(
        //     error.ExpectedNonNullValue,
        //     expectThat(actual).isNotNull(),
        // );
    }
    {
        const actual: ?u1 = 1;
        try expectThat(actual).isNotNull();
        // try std.testing.expectError(
        //     error.ExpectedNull,
        //     expectThat(actual).isNull(),
        // );
    }
}

fn Expectations(comptime T: type) type {
    const type_info = @typeInfo(T);
    return switch (type_info) {
        .optional => Optional(T),
        .null => Null(T),
        else => struct {},
    };
}

fn Null(comptime T: type) type {
    return struct {
        const Self = @This();

        actual: T,
        __null: NullExpectations(Self, "__null") = .{},

        pub fn isNull(self: Self) Error!void {
            try self.__null.isNull();
        }
    };
}

fn NullExpectations(comptime T: type, comptime field_name: []const u8) type {
    return struct {
        const Self = @This();

        pub fn isNull(self: *const Self) Error!void {
            const parent: *const T = @alignCast(@fieldParentPtr(field_name, self));
            if (std.meta.eql(parent.actual, null))
                return;
            std.testing.failPrint(
                \\expected:
                \\    > null
                \\actual:
                \\    {any}
                \\
                \\
            , .{parent.actual});
            return error.ExpectationNotMet;
        }
    };
}

test NullExpectations {
    const T = NullExpectations(struct {}, "__null");
    try std.testing.expect(@hasDecl(T, "isNull"));
    try std.testing.expect(!@hasDecl(T, "isNotNull"));
    try std.testing.expect(!@hasDecl(T, "isEqualTo"));
}

fn Optional(comptime T: type) type {
    return struct {
        const Self = @This();

        actual: T,
        __null: NullExpectations(Self, "__null") = .{},
        __optional: OptionalExpectations(Self, "__optional") = .{},

        pub fn isNull(self: Self) Error!void {
            try self.__null.isNull();
        }

        pub fn isNotNull(self: Self) Error!void {
            try self.__optional.isNotNull();
        }
    };
}

fn OptionalExpectations(comptime T: type, comptime field_name: []const u8) type {
    return struct {
        const Self = @This();

        pub fn isNotNull(self: *const Self) !void {
            const parent: *const T = @alignCast(@fieldParentPtr(field_name, self));
            if (!std.meta.eql(parent.actual, null))
                return;
            std.testing.failPrint(
                \\expected:
                \\    > (non null value)
                \\actual:
                \\    null
                \\
                \\
            , .{});
            return error.ExpectationNotMet;
        }
    };
}

test OptionalExpectations {
    const T = OptionalExpectations(struct {}, "__optional");
    try std.testing.expect(!@hasDecl(T, "isNull"));
    try std.testing.expect(@hasDecl(T, "isNotNull"));
    try std.testing.expect(!@hasDecl(T, "isEqualTo"));
}
