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
    }
    {
        const actual: ?u1 = 1;
        try expectThat(actual).isNotNull();
    }
    {
        const actual: u1 = 1;
        try expectThat(actual).isGreaterThan(0);
    }
    {
        const actual: f32 = 1;
        try expectThat(actual).isGreaterThan(0);
    }
}

test "API usage" {
    {
        const namespace = @TypeOf(expectThat(null));
        try std.testing.expect(@hasDecl(namespace, "isNull"));
        try std.testing.expect(!@hasDecl(namespace, "isNotNull"));
    }
    {
        const namespace = @TypeOf(expectThat(@as(i32, 47)));
        try std.testing.expect(!@hasDecl(namespace, "isNull"));
        try std.testing.expect(!@hasDecl(namespace, "isNotNull"));
        try std.testing.expect(@hasDecl(namespace, "isGreaterThan"));
    }
}

fn Expectations(comptime TActual: type) type {
    const type_info = @typeInfo(TActual);
    return switch (type_info) {
        .int => Int(TActual),
        .optional => Optional(TActual),
        .null => Null(TActual),
        else => @compileError(std.fmt.comptimePrint(
            "Type {s} is not yet supported...",
            .{@typeName(TActual)},
        )),
    };
}

fn Int(comptime TActual: type) type {
    return struct {
        const Self = @This();

        actual: TActual,
        __int: IntExpectations(Self, TActual, "__int") = .{},

        pub fn isGreaterThan(self: Self, expected: TActual) Error!void {
            try self.__int.isGreaterThan(expected);
        }
    };
}

fn IntExpectations(
    comptime TParent: type,
    comptime TExpected: type,
    comptime field_name: []const u8,
) type {
    return struct {
        const Self = @This();

        pub fn isGreaterThan(
            self: *const Self,
            expected: TExpected,
        ) Error!void {
            const parent: *const TParent = @alignCast(@fieldParentPtr(
                field_name,
                self,
            ));
            if (std.math.compare(parent.actual, .gt, expected))
                return;
            std.testing.failPrint(
                \\expected:
                \\    > {any} is not greater than {any}
                \\
                \\
            , .{ parent.actual, expected });
            return error.ExpectationNotMet;
        }
    };
}

fn Optional(comptime TActual: type) type {
    return struct {
        const Self = @This();

        actual: TActual,
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

fn OptionalExpectations(
    comptime TParent: type,
    comptime field_name: []const u8,
) type {
    return struct {
        const Self = @This();

        pub fn isNotNull(self: *const Self) !void {
            const parent: *const TParent = @alignCast(@fieldParentPtr(
                field_name,
                self,
            ));
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

fn Null(comptime TActual: type) type {
    return struct {
        const Self = @This();

        actual: TActual,
        __null: NullExpectations(Self, "__null") = .{},

        pub fn isNull(self: Self) Error!void {
            try self.__null.isNull();
        }
    };
}

fn NullExpectations(
    comptime TParent: type,
    comptime field_name: []const u8,
) type {
    return struct {
        const Self = @This();

        pub fn isNull(self: *const Self) Error!void {
            const parent: *const TParent = @alignCast(@fieldParentPtr(
                field_name,
                self,
            ));
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
