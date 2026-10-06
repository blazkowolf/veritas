const std = @import("std");

pub fn Expectations(comptime T: type) type {
    const type_info = @typeInfo(T);
    return switch (type_info) {
        .optional => struct {
            actual: T,

            pub fn isNull(self: @This()) !void {
                try std.testing.expectEqual(null, self.actual);
            }

            pub fn isNotNull(self: @This()) !void {
                try std.testing.expect(null != self.actual);
            }

            pub fn isEqualTo(self: @This(), expected: T) !void {
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

/// This function is intended to be used only in tests.
pub fn expectThat(actual: anytype) Expectations(@TypeOf(actual)) {
    return .{ .actual = actual };
}

test "null decls" {
    const expectations = expectThat(null);
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isNull"));
    try std.testing.expect(!@hasDecl(@TypeOf(expectations), "isNotNull"));
    try std.testing.expect(!@hasDecl(@TypeOf(expectations), "isEqualTo"));
}

test "null optional decls" {
    const a: ?u1 = null;
    const expectations = expectThat(a);
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isNull"));
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isNotNull"));
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "isEqualTo"));
    try std.testing.expect(@hasDecl(@TypeOf(expectations), "blah"));
}
