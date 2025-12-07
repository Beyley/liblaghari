const std = @import("std");
const builtin = @import("builtin");

const dvui = @import("dvui");
pub const main = dvui.App.main;
pub const panic = dvui.App.panic;
const laghari = @import("laghari");
const hekenic = laghari.time.hekenic;
const zeit = @import("zeit");

pub const dvui_app: dvui.App = .{
    .config = .{
        .options = .{
            .size = .{ .w = 800.0, .h = 600.0 },
            .min_size = .{ .w = 250.0, .h = 350.0 },
            .title = "Laghari Calendars",
            // .icon = window_icon_png,
            .window_init_options = .{
                // Could set a default theme here
                // .theme = dvui.Theme.builtin.dracula,
            },
            .vsync = true,
        },
    },
    .frameFn = frame,
    .initFn = init,
    .deinitFn = deinit,
};
pub const std_options: std.Options = .{
    .logFn = dvui.App.logFn,
};

var debug_allocator_instance = std.heap.DebugAllocator(.{}){};
const gpa =
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe)
        debug_allocator_instance.allocator()
    else
        std.heap.smp_allocator;

var orig_content_scale: f32 = 1.0;
var warn_on_quit: bool = false;
var warn_on_quit_closing: bool = false;

var state_init: bool = false;
var state: struct {
    env_map: std.process.EnvMap,
    local_timezone: zeit.TimeZone,
    now: zeit.Instant,
    now_hekenic: hekenic.YearMonthDay,
} = undefined;

// Runs before the first frame, after backend and dvui.Window.init()
// - runs between win.begin()/win.end()
pub fn init(win: *dvui.Window) !void {
    {
        var env_map = try std.process.getEnvMap(gpa);
        errdefer env_map.deinit();

        const local_timezone = try zeit.local(gpa, &env_map);
        errdefer local_timezone.deinit();

        const now = try zeit.instant(.{ .timezone = &local_timezone });
        const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = @intCast(now.timezone.adjust(now.unixTimestamp()).timestamp) };
        const epoch_day = epoch_seconds.getEpochDay();
        const now_hekenic: hekenic.YearMonthDay = .fromGregorianEpochDay(epoch_day);

        state = .{
            .env_map = env_map,
            .local_timezone = local_timezone,
            .now = now,
            .now_hekenic = now_hekenic,
        };

        state_init = true;
    }

    orig_content_scale = win.content_scale;
    // Add your own bundled font files...:
    // try dvui.addFont("NOTO", @embedFile("../src/fonts/NotoSansKR-Regular.ttf"), null);

    // Or opt-in to adding the fonts for the builin themes...
    try win.fonts.addBuiltinFontsForTheme(win.gpa, dvui.Theme.builtin.adwaita_light);

    // Or add other builtin fonts
    try win.fonts.addBuiltinFonts(win.gpa, &.{.Vera});

    if (false) {
        // If you need to set a theme based on the users preferred color scheme, do it here
        win.theme = switch (win.backend.preferredColorScheme() orelse .light) {
            .light => dvui.Theme.builtin.adwaita_light,
            .dark => dvui.Theme.builtin.adwaita_dark,
        };
    }
}

// Run as app is shutting down before dvui.Window.deinit()
pub fn deinit() void {
    if (state_init) {
        state.env_map.deinit();
        state.local_timezone.deinit();
    }

    if (debug_allocator_instance.deinit() == .leak) {
        @panic("Memory allocator leaked");
    }
}

pub fn frame() !dvui.App.Result {
    var scaler = dvui.scale(@src(), .{
        .scale = &dvui.currentWindow().content_scale,
        .pinch_zoom = .global,
    }, .{
        .rect = .cast(dvui.windowRect()),
    });
    scaler.deinit();

    // {
    //     var hbox = dvui.box(@src(), .{
    //         .dir = .horizontal,
    //     }, .{
    //         .style = .window,
    //         .background = true,
    //         .expand = .horizontal,
    //     });
    //     defer hbox.deinit();

    //     var m = dvui.menu(@src(), .horizontal, .{});
    //     defer m.deinit();

    //     if (dvui.menuItemLabel(@src(), "File", .{ .submenu = true }, .{ .tag = "first-focusable" })) |r| {
    //         var fw = dvui.floatingMenu(@src(), .{ .from = r }, .{});
    //         defer fw.deinit();

    //         if (dvui.menuItemLabel(@src(), "Close Menu", .{}, .{ .expand = .horizontal }) != null) {
    //             m.close();
    //         }

    //         if (dvui.backend.kind != .web) {
    //             if (dvui.menuItemLabel(@src(), "Exit", .{}, .{ .expand = .horizontal }) != null) {
    //                 return .close;
    //             }
    //         }
    //     }
    // }

    var scroll = dvui.scrollArea(@src(), .{}, .{
        .style = .window,

        .padding = .all(4),

        .expand = .both,
    });
    defer scroll.deinit();

    const corner_radius: dvui.Rect = .all(5);

    {
        var vbox = dvui.box(@src(), .{}, .{
            .style = .content,

            .background = true,
            .padding = .all(4),
        });
        defer vbox.deinit();

        dvui.label(@src(), "{s}", .{state.now_hekenic.month.fontName(.english).?}, .{
            .font_style = .title,
        });

        for (0..(hekenic.days_per_month / hekenic.days_per_week)) |week_index| {
            var box = dvui.flexbox(@src(), .{
                .justify_content = .center,
            }, .{
                .id_extra = week_index,
                .padding = .all(4),
            });
            defer box.deinit();

            const day_size: dvui.Size = .{ .w = 65, .h = 65 };

            // for (0..hekenic.months_per_year) |month| {
            for (0..hekenic.days_per_week) |week_day_index| {
                const day_index = @as(usize, @intFromEnum(state.now_hekenic.month)) * hekenic.days_per_month + week_index * hekenic.days_per_week + week_day_index;
                const now_day_index = state.now_hekenic.day() - 1;

                var day_box = dvui.box(@src(), .{}, .{
                    .id_extra = day_index,

                    .margin = .all(4),
                    .padding = .all(4),

                    .min_size_content = day_size,
                    .max_size_content = .size(day_size),

                    .color_fill = if (day_index == now_day_index) .gray else dvui.Color.gray.lighten(-50),

                    .corner_radius = corner_radius,

                    .background = true,
                });
                defer day_box.deinit();

                dvui.label(@src(), "{d}", .{day_index + 1}, .{
                    .style = .content,
                });
            }
            // }
        }
    }

    // {
    //     var tl = dvui.textLayout(@src(), .{}, .{ .expand = .horizontal, .font_style = .title_4 });
    //     defer tl.deinit();

    //     const lorem = "This is a dvui.App example that can compile on multiple backends.";
    //     tl.addText(lorem, .{});
    //     tl.addText("\n\n", .{});
    //     tl.format("Current backend: {s}", .{@tagName(dvui.backend.kind)}, .{});
    //     if (dvui.backend.kind == .web) {
    //         tl.format(" : {s}", .{if (dvui.backend.wasm.wasm_about_webgl2() == 1) "webgl2" else "webgl (no mipmaps)"}, .{});
    //     }
    // }

    // {
    //     var tl = dvui.textLayout(@src(), .{}, .{ .expand = .horizontal });
    //     defer tl.deinit();

    //     tl.addText(
    //         \\DVUI
    //         \\- paints the entire window
    //         \\- can show floating windows and dialogs
    //         \\- rest of the window is a scroll area
    //     , .{});
    //     tl.addText("\n\n", .{});
    //     tl.addText("Framerate is variable and adjusts as needed for input events and animations.", .{});
    //     tl.addText("\n\n", .{});
    //     tl.addText("Framerate is capped by vsync.", .{});
    //     tl.addText("\n\n", .{});
    //     tl.addText("Cursor is always being set by dvui.", .{});
    //     tl.addText("\n\n", .{});
    //     if (dvui.useFreeType) {
    //         tl.addText("Fonts are being rendered by FreeType 2.", .{});
    //     } else {
    //         tl.addText("Fonts are being rendered by stb_truetype.", .{});
    //     }
    // }

    const label = if (dvui.Examples.show_demo_window) "Hide Demo Window" else "Show Demo Window";
    if (dvui.button(@src(), label, .{}, .{ .tag = "show-demo-btn" })) {
        dvui.Examples.show_demo_window = !dvui.Examples.show_demo_window;
    }

    if (dvui.button(@src(), "Debug Window", .{}, .{})) {
        dvui.toggleDebugWindow();
    }

    {
        var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{});
        defer hbox.deinit();
        dvui.label(@src(), "Pinch Zoom or Scale", .{}, .{});
        if (dvui.buttonIcon(@src(), "plus", dvui.entypo.plus, .{}, .{}, .{})) {
            dvui.currentWindow().content_scale *= 1.1;
        }

        if (dvui.buttonIcon(@src(), "minus", dvui.entypo.minus, .{}, .{}, .{})) {
            dvui.currentWindow().content_scale /= 1.1;
        }

        if (dvui.currentWindow().content_scale != orig_content_scale) {
            if (dvui.button(@src(), "Reset Scale", .{}, .{})) {
                dvui.currentWindow().content_scale = orig_content_scale;
            }
        }
    }

    if (dvui.backend.kind != .web) {
        _ = dvui.checkbox(@src(), &warn_on_quit, "Warn on Quit", .{});

        if (warn_on_quit) {
            if (warn_on_quit_closing) return .close;

            const wd = dvui.currentWindow().data();
            for (dvui.events()) |*e| {
                if (!dvui.eventMatchSimple(e, wd)) continue;

                if ((e.evt == .window and e.evt.window.action == .close) or (e.evt == .app and e.evt.app.action == .quit)) {
                    e.handle(@src(), wd);

                    const warnAfter: dvui.DialogCallAfterFn = struct {
                        fn warnAfter(_: dvui.Id, response: dvui.enums.DialogResponse) !void {
                            if (response == .ok) warn_on_quit_closing = true;
                        }
                    }.warnAfter;

                    dvui.dialog(@src(), .{}, .{ .message = "Really Quit?", .cancel_label = "Cancel", .callafterFn = warnAfter });
                }
            }
        }
    }

    // look at demo() for examples of dvui widgets, shows in a floating window
    dvui.Examples.demo();

    return .ok;
}
