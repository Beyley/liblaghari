const std = @import("std");
const epoch = std.time.epoch;

const @"o'eaiaa" = @import("laghari").time.@"o'eaiaa";
const dvui = @import("dvui");

const colors = @import("../colors.zig");
const State = @import("../gui.zig").State;
const shared = @import("shared.zig");

pub fn title(state: State) !void {
    dvui.label(@src(), "{s}", .{
        state.now.@"o'eaiaa".month.fontNameSafe(.english),
    }, .{
        // .font_style = .title,
        .font = dvui.themeGet().font_title,
        .color_text = colors.laghari,
    });
}

pub fn frame(state: State) !void {
    const now = state.now.@"o'eaiaa";

    // o'eaiaa uses a base 8 number system
    const days_per_week = 8;

    const days_in_month = now.month.days(now.year);

    for (0..std.math.divCeil(usize, days_in_month, days_per_week) catch unreachable) |week_index| {
        var box = shared.week(week_index);
        defer box.deinit();

        for (0..days_per_week) |week_day_index| {
            const month_day_index = week_index * days_per_week + week_day_index;
            if (month_day_index >= days_in_month) {
                break;
            }

            const year_month_day: @"o'eaiaa".YearMonthDay = .{
                .month = now.month,
                .year = now.year,
                .month_day_index = @intCast(month_day_index),
            };

            try shared.day(state, .{
                .epoch_day = year_month_day.toGregorianEpochDay(),
                .normal_colour = colors.slight_solar_highlight,
                .highlighted_colour = colors.strong_solar_highlight,
                .text_colour = colors.laghari,
                .flexbox = box,
                .week_index = week_index,
            }, "{d}", .{month_day_index + 1});
        }
        // }
    }
}
