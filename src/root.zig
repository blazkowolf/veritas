const std = @import("std");

/// This function is intended to be used only in tests.
pub fn expectThat(actual: anytype) Expectations(@TypeOf(actual)) {
    return .{ ._actual = actual };
}

fn Expectations(comptime T: type) type {
    const type_info = @typeInfo(T);
    return switch (type_info) {
        .optional => struct {
            const Self = @This();

            _actual: T,
            _null_expectations: NullExpectations(Self) = .{},
            _optional_expectations: OptionalExpectations(Self) = .{},

            pub fn isNull(self: Self) !void {
                try self._null_expectations.isNull();
            }

            pub fn isNotNull(self: Self) !void {
                try self._optional_expectations.isNotNull();
            }

            pub fn isEqualTo(self: Self, expected: T) !void {
                try self.isNotNull();
                try std.testing.expectEqual(expected, self._actual);
            }
        },
        .null => struct {
            const Self = @This();

            _actual: T,
            _null_expectations: NullExpectations(Self) = .{},

            pub fn isNull(self: Self) !void {
                try self._null_expectations.isNull();
            }
        },
        else => struct {},
    };
}

fn NullExpectations(comptime T: type) type {
    return struct {
        const Self = @This();

        pub fn isNull(self: *Self) !void {
            const parent: *T = @alignCast(@fieldParentPtr("_null_expectations", self));
            if (std.meta.eql(parent._actual, null))
                return;
            std.testing.failPrint(
                \\expected:
                \\    > null
                \\actual:
                \\    {any}
                \\
            , .{parent._actual});
            return error.ExpectationFailed;
        }
    };
}

test NullExpectations {
    const T = NullExpectations(struct {
        _actual: null,
        _null_expectations: NullExpectations(@This()) = .{},
    });
    // const expectations = expectThat(null);
    try std.testing.expect(@hasDecl(T, "isNull"));
    try std.testing.expect(!@hasDecl(T, "isNotNull"));
    try std.testing.expect(!@hasDecl(T, "isEqualTo"));
}


fn OptionalExpectations(comptime T: type) type {
    return struct {
        const Self = @This();

        pub fn isNotNull(self: *const Self) !void {
            const parent: *const T = @alignCast(@fieldParentPtr("_optional_expectations", self));
            if (!std.meta.eql(parent._actual, null))
                return;
            std.testing.failPrint(
                \\expected:
                \\    > (non null value)
                \\actual:
                \\    null
                \\
            , .{});
            return error.ExpectationFailed;
        }
    };
}

test OptionalExpectations {
    const a: ?u1 = 1;
    const expectations = expectThat(a);
    try std.testing.expect(!@hasDecl(@TypeOf(expectations), "isNull"));
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isNotNull"));
    try std.testing.expect(!@hasDecl(@TypeOf(expectations), "isEqualTo"));
    try expectations.isNotNull();
}
