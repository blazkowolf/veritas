const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run tests");
    const docs_step = b.step("docs", "Emit documentation");

    const mod = b.addModule("veritas", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    test_step.dependOn(&run_mod_tests.step);

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = b.addLibrary(.{
            .name = "veritas",
            .root_module = mod,
        }).getEmittedDocs(),
    });

    docs_step.dependOn(&docs_install.step);
    b.getInstallStep().dependOn(docs_step);
}
