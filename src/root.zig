const std = @import("std");

/// This function is intended to be used only in tests.
pub fn expectThat(actual: anytype) Expectations(@TypeOf(actual)) {
    return .{ .actual = actual };
}

test expectThat {
    // {
    //     const actual: ?void = null;
    //     try expectThat(actual).isNull();
    // }
    {
        const actual: ?u0 = null;
        try expectThat(actual).isNull();
        try std.testing.expectError(
            error.ExpectedNonNullValue, 
            expectThat(actual).isNotNull(),
        );
    }
    {
        const actual: ?u1 = 1;
        try expectThat(actual).isNotNull();
        try std.testing.expectError(
            error.ExpectedNull, 
            expectThat(actual).isNull(),
        );
    }
}

fn Expectations(comptime T: type) type {
    const type_info = @typeInfo(T);
    return switch (type_info) {
        .optional => struct {
            const Self = @This();

            actual: T,
            __null_expectations: NullExpectations(Self) = .{},
            __optional_expectations: OptionalExpectations(Self) = .{},

            pub fn isNull(self: Self) NullExpectations(Self).Error!void {
                try self.__null_expectations.isNull();
            }

            pub fn isNotNull(self: Self) OptionalExpectations(Self).Error!void {
                try self.__optional_expectations.isNotNull();
            }
        },
        .null => struct {
            const Self = @This();

            actual: T,
            __null_expectations: NullExpectations(Self) = .{},

            pub fn isNull(self: Self) NullExpectations(Self).Error!void {
                try self.__null_expectations.isNull();
            }
        },
        else => struct {},
    };
}

fn NullExpectations(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Error = error{ExpectedNull};

        pub fn isNull(self: *const Self) Error!void {
            const parent: *const T = @alignCast(@fieldParentPtr("__null_expectations", self));
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
            return error.ExpectedNull;
        }
    };
}

test NullExpectations {
    const T = NullExpectations(struct {});
    try std.testing.expect(@hasDecl(T, "isNull"));
    try std.testing.expect(!@hasDecl(T, "isNotNull"));
    try std.testing.expect(!@hasDecl(T, "isEqualTo"));
}


fn OptionalExpectations(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Error = error{ExpectedNonNullValue};

        pub fn isNotNull(self: *const Self) !void {
            const parent: *const T = @alignCast(@fieldParentPtr("__optional_expectations", self));
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
            return error.ExpectedNonNullValue;
        }
    };
}

test OptionalExpectations {
    const T = OptionalExpectations(struct {});
    // const a: ?u1 = 1;
    // const expectations = expectThat(a);
    try std.testing.expect(!@hasDecl(T, "isNull"));
    try std.testing.expect(@hasDecl(T, "isNotNull"));
    try std.testing.expect(!@hasDecl(T, "isEqualTo"));
    // try expectations.isNotNull();
}
