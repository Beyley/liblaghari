const std = @import("std");
const epoch = std.time.epoch;

const dvui = @import("dvui");
const martian = @import("laghari").time.martian;

const colors = @import("../colors.zig");
const State = @import("../gui.zig").State;
const shared = @import("shared.zig");

pub fn title(state: *const State) !void {
    _ = state;

    dvui.label(@src(), "{s}", .{
        "Martian",
    }, .{
        // .font_style = .title,
        .font = dvui.themeGet().font_title,
        .color_text = colors.laghari,
    });
}

pub fn frame(state: *const State) !void {
    const now = state.now.martian;

    const year_start_epoch_day = now.yearStart().toGregorianEpochDay();

    // video uses 16 day as separator, let's go with that too!
    const days_per_week = 16;

    for (0..std.math.divCeil(usize, martian.days_per_year, days_per_week) catch unreachable) |week_index| {
        var box = shared.week(week_index);
        defer box.deinit();

        for (0..days_per_week) |week_day_index| {
            const day_index = week_index * days_per_week + week_day_index;
            if (day_index >= martian.days_per_year) {
                break;
            }

            try shared.day(state, .{
                .epoch_day = .{ .day = @intCast(year_start_epoch_day.day + day_index) },
                .flexbox = box,
                .week_index = week_index,
            }, "{d}", .{day_index + 1});
        }
    }
}
