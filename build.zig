const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zeit_mod = b.dependency("zeit", .{
        .target = target,
        .optimize = optimize,
    }).module("zeit");

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (target.result.cpu.arch == .wasm32 or target.result.cpu.arch == .wasm64) {
        const wasm_lib = b.addExecutable(.{
            .name = "laghari",
            .root_module = lib_mod,
        });
        wasm_lib.rdynamic = true;
        wasm_lib.entry = .disabled;
        b.installArtifact(wasm_lib);
    } else {
        const link_modes: []const std.builtin.LinkMode = &.{ .static, .dynamic };

        for (link_modes) |link_mode| {
            const lib = b.addLibrary(.{
                .linkage = link_mode,
                .name = "laghari",
                .root_module = lib_mod,
            });
            b.installArtifact(lib);
        }

        const exe_mod = b.createModule(.{
            .root_source_file = b.path("src/exe/cli.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "laghari", .module = lib_mod },
                .{ .name = "zeit", .module = zeit_mod },
            },
        });

        const exe = b.addExecutable(.{
            .name = "laghari-cli",
            .root_module = exe_mod,
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
