const std = @import("std");
const epoch = std.time.epoch;

const dvui = @import("dvui");
const hekenic = @import("laghari").time.hekenic;

const colors = @import("../colors.zig");
const State = @import("../gui.zig").State;
const shared = @import("shared.zig");

pub fn title(state: State) !void {
    dvui.label(@src(), "{s}", .{
        state.now.hekenic.month.fontNameSafe(.english),
    }, .{
        // .font_style = .title,
        .font = dvui.themeGet().font_title,
        .color_text = colors.laghari,
    });
}

pub fn frame(state: State) !void {
    const year_start_epoch_day = state.now.hekenic.yearStart().toGregorianEpochDay();

    for (0..@divExact(hekenic.days_per_month, hekenic.days_per_week)) |week_index| {
        var box = shared.week(week_index);
        defer box.deinit();

        // for (0..hekenic.months_per_year) |month| {
        for (0..hekenic.days_per_week) |week_day_index| {
            const day_index = @as(usize, @intFromEnum(state.now.hekenic.month)) * hekenic.days_per_month //
            + week_index * hekenic.days_per_week //
            + week_day_index;

            try shared.day(state, .{
                .epoch_day = .{ .day = @intCast(year_start_epoch_day.day + day_index) },
                .normal_colour = colors.slight_solar_highlight,
                .highlighted_colour = colors.strong_solar_highlight,
                .text_colour = colors.laghari,
                .flexbox = box,
                .week_index = week_index,
            }, "{d}", .{day_index + 1});
        }
        // }
    }
}
