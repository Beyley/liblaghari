const std = @import("std");
const epoch = std.time.epoch;
const builtin = @import("builtin");

const dvui = @import("dvui");
pub const main = dvui.App.main;
pub const panic = dvui.App.panic;
const laghari = @import("laghari");
const hekenic = laghari.time.hekenic;
const @"o'eaiā" = laghari.time.@"o'eaiā";
const gregorian = laghari.time.gregorian;
const martian = laghari.time.martian;
const zeit = @import("zeit");

const calendars = @import("calendars/calendars.zig");
const colors = @import("colors.zig");
const Options = @import("Options.zig");

const lato_light_family = "Lato Light";
const lato_regular_family = "Lato Regular";

const fonts: []const dvui.Font.Source = &.{
    .{
        .family = dvui.Font.array(lato_light_family),
        .bytes = @embedFile("fonts/Lato/Lato-Light.ttf"),
    },
    .{
        .family = dvui.Font.array(lato_regular_family),
        .bytes = @embedFile("fonts/Lato/Lato-Regular.ttf"),
    },
};

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
                .theme = .{
                    .name = "Laghari Portals",
                    .dark = true,

                    .embedded_fonts = fonts,

                    .font_body = .find(.{ .family = lato_light_family, .size = 20 }),
                    .font_heading = .find(.{ .family = lato_regular_family }),
                    .font_title = .find(.{ .family = lato_regular_family, .size = 40 }),
                    .font_mono = .find(.{ .family = lato_light_family }), // todo

                    .text = colors.bright,
                    .fill = .black,
                    .focus = .gray,
                    .border = colors.laghari,

                    .control = .{
                        .fill = .black,
                        .fill_hover = colors.laghari,

                        .border = colors.laghari,

                        .text = colors.laghari,
                        .text_hover = .black,
                    },
                    .window = .{
                        .text = colors.bright,
                        .fill = .black,
                        .border = colors.laghari,
                    },
                    .highlight = .{
                        .fill = .black,
                        .border = colors.laghari,
                        .text = colors.laghari,
                    },
                    .err = .{
                        .fill = .black,
                        .border = colors.laghari,
                        .text = colors.err,
                    },
                    .app1 = .{
                        .fill = colors.strong_highlight,
                        .text = colors.laghari,
                    },
                    .app2 = .{
                        .fill = colors.slight_highlight,
                        .text = colors.laghari,
                    },
                    .app3 = .{
                        .fill = .transparent,
                        .text = colors.laghari,
                    },
                },
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

pub const State = struct {
    pub const Now = struct {
        instant: zeit.Instant,
        epoch_seconds: epoch.EpochSeconds,
        epoch_day: epoch.EpochDay,
        epoch_year_day: epoch.YearAndDay,
        epoch_month_day: epoch.MonthAndDay,
        hekenic: hekenic.YearMonthDay,
        martian: martian.YearDay,
        @"o'eaiā": @"o'eaiā".YearMonthDay,
        gregorian: gregorian.YearMonthDay,

        pub fn fromInstant(instant: zeit.Instant) Now {
            const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = @intCast(instant.timezone.adjust(instant.unixTimestamp()).timestamp) };
            const epoch_day = epoch_seconds.getEpochDay();
            const epoch_year_day = epoch_day.calculateYearDay();
            const epoch_month_day = epoch_year_day.calculateMonthDay();
            const instant_hekenic: hekenic.YearMonthDay = .fromGregorianEpochDay(epoch_day);
            const instant_martian = martian.YearDay.fromGregorianEpochDay(epoch_day);
            const @"instant_o'eaiaa": @"o'eaiā".YearMonthDay = .fromGregorianEpochDay(epoch_day);
            const instant_gregorian: gregorian.YearMonthDay = .fromEpochDay(epoch_day);

            return .{
                .instant = instant,
                .epoch_seconds = epoch_seconds,
                .epoch_day = epoch_day,
                .epoch_year_day = epoch_year_day,
                .epoch_month_day = epoch_month_day,
                .hekenic = instant_hekenic,
                .martian = instant_martian,
                .@"o'eaiā" = @"instant_o'eaiaa",
                .gregorian = instant_gregorian,
            };
        }
    };

    env_map: std.process.EnvMap,
    local_timezone: zeit.TimeZone,

    /// Roughly when now is
    now: Now,
    /// The time of the user's "cursor"
    cursor_time: Now,

    options: Options,
};

var state_init: bool = false;
var state: State = undefined;

// Runs before the first frame, after backend and dvui.Window.init()
// - runs between win.begin()/win.end()
pub fn init(win: *dvui.Window) !void {
    {
        var env_map = try std.process.getEnvMap(gpa);
        errdefer env_map.deinit();

        const local_timezone = try zeit.local(gpa, &env_map);
        errdefer local_timezone.deinit();

        const now = try zeit.instant(.{ .timezone = &local_timezone });

        const now_state: State.Now = .fromInstant(now);

        state = .{
            .env_map = env_map,
            .local_timezone = local_timezone,

            .now = now_state,
            .cursor_time = now_state,

            .options = .{
                .calendar = .hekenic,
            },
        };

        state_init = true;
    }

    orig_content_scale = win.content_scale;
    // Add your own bundled font files...:
    // try dvui.addFont("NOTO", @embedFile("../src/fonts/NotoSansKR-Regular.ttf"), null);

    // Or opt-in to adding the fonts for the builin themes...
    // try win.fonts.addBuiltinFontsForTheme(win.gpa, dvui.Theme.builtin.adwaita_light);

    // Or add other builtin fonts
    // try win.fonts.addBuiltinFonts(win.gpa, &.{.Vera});

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

    {
        var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{ .style = .window, .background = true, .expand = .horizontal });
        defer hbox.deinit();

        var m = dvui.menu(@src(), .horizontal, .{});
        defer m.deinit();

        if (dvui.menuItemLabel(
            @src(),
            "Options",
            .{ .submenu = true },
            .{ .tag = "first-focusable", .style = .control },
        )) |options_r| {
            var options_fw = dvui.floatingMenu(@src(), .{ .from = options_r }, .{});
            defer options_fw.deinit();

            if (dvui.menuItemLabel(
                @src(),
                "Calendar",
                .{ .submenu = true },
                .{ .style = .control },
            )) |calendar_r| {
                var calendar_fw = dvui.floatingMenu(@src(), .{ .from = calendar_r }, .{});
                defer calendar_fw.deinit();

                if (dvui.menuItemLabel(@src(), "Gregorian", .{}, .{
                    .expand = .horizontal,
                }) != null) {
                    state.options.calendar = .gregorian;
                    options_fw.close();
                }
                if (dvui.menuItemLabel(@src(), "Hekenic", .{}, .{
                    .expand = .horizontal,
                }) != null) {
                    state.options.calendar = .hekenic;
                    options_fw.close();
                }
                if (dvui.menuItemLabel(@src(), "Martian", .{}, .{
                    .expand = .horizontal,
                }) != null) {
                    state.options.calendar = .martian;
                    options_fw.close();
                }
                if (dvui.menuItemLabel(@src(), "O'eaiā", .{}, .{
                    .expand = .horizontal,
                }) != null) {
                    state.options.calendar = .@"o'eaiā";
                    options_fw.close();
                }
            }
        }
    }

    {
        var vbox = dvui.box(@src(), .{}, .{
            .style = .content,

            .background = true,
            .padding = .all(4),
        });
        defer vbox.deinit();

        {
            switch (state.options.calendar) {
                .gregorian => try calendars.gregorian.title(&state),
                .hekenic => try calendars.hekenic.title(&state),
                .martian => try calendars.martian.title(&state),
                .@"o'eaiā" => try calendars.@"o'eaiā".title(&state),
            }
        }

        _ = dvui.separator(@src(), .{ .expand = .horizontal });

        {
            var calendar_scroll = dvui.scrollArea(@src(), .{}, .{
                .style = .window,

                .padding = .all(4),

                .expand = .both,
            });
            defer calendar_scroll.deinit();

            switch (state.options.calendar) {
                .gregorian => try calendars.gregorian.frame(&state),
                .hekenic => try calendars.hekenic.frame(&state),
                .martian => try calendars.martian.frame(&state),
                .@"o'eaiā" => try calendars.@"o'eaiā".frame(&state),
            }
        }
    }

    if (builtin.mode == .Debug) {
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
    }

    return .ok;
}
