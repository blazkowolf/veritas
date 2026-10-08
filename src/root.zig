const std = @import("std");

/// This function is intended to be used only in tests.
pub fn expectThat(actual: anytype) Expectations(@TypeOf(actual)) {
    return .{ .actual = actual };
}

fn Expectations(comptime T: type) type {
    const type_info = @typeInfo(T);
    return switch (type_info) {
        .optional => struct {
            actual: T,

            const Self = @This();

            pub fn isNull(self: Self) !void {
                if (std.meta.eql(self.actual, null))
                    return;
                std.testing.failPrint(
                    \\expected:
                    \\    > null
                    \\actual:
                    \\    {any}
                    \\
                , .{self.actual});
                return error.ExpectationFailed;
            }

            pub fn isNotNull(self: Self) !void {
                if (!std.meta.eql(self.actual, null))
                    return;
                std.testing.failPrint(
                    \\expected:
                    \\    > not null
                    \\actual:
                    \\    null
                    \\
                , .{});
                return error.ExpectationFailed;
            }

            pub fn isEqualTo(self: Self, expected: T) !void {
                try self.isNotNull();
                try std.testing.expectEqual(expected, self.actual);
            }
        },
        .null => struct {
            actual: T,

            pub fn isNull(self: @This()) !void {
                try std.testing.expectEqual(null, self.actual);
            }
        },
        else => struct {},
    };
}

// fn NullExpectations(comptime T: type) type {
//     return struct {
//         const Self = @This();
//     };
// }

test "null decls" {
    const expectations = expectThat(null);
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isNull"));
    try std.testing.expect(!@hasDecl(@TypeOf(expectations), "isNotNull"));
    try std.testing.expect(!@hasDecl(@TypeOf(expectations), "isEqualTo"));
}

test "null optional decls" {
    const a: ?u1 = 1;
    const expectations = expectThat(a);
    try expectThat(a).isNull();
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isNull"));
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isNotNull"));
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isEqualTo"));
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "blah"));
}
