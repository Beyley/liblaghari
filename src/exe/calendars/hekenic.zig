const std = @import("std");
const epoch = std.time.epoch;

const dvui = @import("dvui");
const hekenic = @import("laghari").time.hekenic;

const colors = @import("../colors.zig");
const State = @import("../gui.zig").State;
const shared = @import("shared.zig");

pub fn frame(state: State) !void {
    dvui.label(@src(), "{s}", .{
        state.now.hekenic.month.fontNameSafe(.english),
    }, .{
        // .font_style = .title,
        .font = dvui.themeGet().font_title,
    });

    const year_start_epoch_day = state.now.hekenic.yearStart().toGregorianEpochDay();

    for (0..@divExact(hekenic.days_per_month, hekenic.days_per_week)) |week_index| {
        var box = dvui.flexbox(@src(), .{
            .justify_content = .start,
        }, .{
            .id_extra = week_index,
            .margin = .all(4),
        });
        defer box.deinit();

        // for (0..hekenic.months_per_year) |month| {
        for (0..hekenic.days_per_week) |week_day_index| {
            const day_index = @as(usize, @intFromEnum(state.now.hekenic.month)) * hekenic.days_per_month //
            + week_index * hekenic.days_per_week //
            + week_day_index;

            try shared.day(state, .{
                .epoch_day = .{ .day = @intCast(year_start_epoch_day.day + day_index) },
                .last_day_in_row = week_day_index == hekenic.days_per_week - 1,
                .normal_colour = colors.slight_solar_highlight,
                .highlighted_colour = colors.strong_solar_highlight,
            }, "{d}", .{day_index + 1});
        }
        // }
    }
}
