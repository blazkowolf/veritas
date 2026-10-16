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
        // try expectThat(actual).isLessThan(2); // is compile error because "2" cannot fit inside a `u1`
        try expectThat(actual).isGreaterThanOrEqualTo(1);
    }
    {
        const actual: i32 = 1;
        try expectThat(actual).isLessThan(100);
        try expectThat(actual).isLessThanOrEqualTo(1);
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
        __ordered: OrderedExpectations(Self, TActual, "__ordered") = .{},

        pub fn isGreaterThan(self: Self, expected: TActual) Error!void {
            try self.__ordered.isGreaterThan(expected);
        }

        pub fn isGreaterThanOrEqualTo(self: Self, expected: TActual) Error!void {
            try self.__ordered.isGreaterThanOrEqualTo(expected);
        }

        pub fn isLessThan(self: Self, expected: TActual) Error!void {
            try self.__ordered.isLessThan(expected);
        }

        pub fn isLessThanOrEqualTo(self: Self, expected: TActual) Error!void {
            try self.__ordered.isLessThanOrEqualTo(expected);
        }
    };
}

fn OrderedExpectations(
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

        pub fn isLessThan(
            self: *const Self,
            expected: TExpected,
        ) Error!void {
            const parent: *const TParent = @alignCast(@fieldParentPtr(
                field_name,
                self,
            ));
            if (std.math.compare(parent.actual, .lt, expected))
                return;
            std.testing.failPrint(
                \\expected:
                \\    > {any} is not less than {any}
                \\
                \\
            , .{ parent.actual, expected });
            return error.ExpectationNotMet;
        }

        pub fn isGreaterThanOrEqualTo(
            self: *const Self,
            expected: TExpected,
        ) Error!void {
            const parent: *const TParent = @alignCast(@fieldParentPtr(
                field_name,
                self,
            ));
            if (std.math.compare(parent.actual, .gte, expected))
                return;
            std.testing.failPrint(
                \\expected:
                \\    > {any} is not greater than or equal to {any}
                \\
                \\
            , .{ parent.actual, expected });
            return error.ExpectationNotMet;
        }

        pub fn isLessThanOrEqualTo(
            self: *const Self,
            expected: TExpected,
        ) Error!void {
            const parent: *const TParent = @alignCast(@fieldParentPtr(
                field_name,
                self,
            ));
            if (std.math.compare(parent.actual, .lte, expected))
                return;
            std.testing.failPrint(
                \\expected:
                \\    > {any} is not less than or equal to {any}
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
            const parent = getParentPtr(TParent, Self, field_name, self);
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

fn getParentPtr(
    comptime TParent: type,
    comptime T: type,
    comptime field_name: []const u8,
    field_ptr: *const T,
) *const TParent {
    return @alignCast(@fieldParentPtr(field_name, field_ptr));
}
