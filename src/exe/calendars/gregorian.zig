const std = @import("std");
const epoch = std.time.epoch;

const dvui = @import("dvui");
const gregorian = @import("laghari").time.gregorian;

const colors = @import("../colors.zig");
const State = @import("../gui.zig").State;
const shared = @import("shared.zig");

pub fn title(state: *const State) !void {
    dvui.label(@src(), "{s}", .{
        switch (state.now.epoch_month_day.month) {
            .jan => "January",
            .feb => "February",
            .mar => "March",
            .apr => "April",
            .may => "May",
            .jun => "June",
            .jul => "July",
            .aug => "August",
            .sep => "September",
            .oct => "October",
            .nov => "November",
            .dec => "December",
        },
    }, .{
        // .font_style = .title,
        .font = dvui.themeGet().font_title,
        .color_text = colors.laghari,
    });
}

pub fn frame(state: *const State) !void {
    const now = state.now.gregorian;

    const days_in_month = now.month.daysInMonth(now.year);

    const month_start_epoch_day = now.monthStart().toEpochDay();

    for (0..std.math.divCeil(usize, days_in_month, gregorian.days_per_week) catch unreachable) |week_index| {
        var box = shared.week(week_index);
        defer box.deinit();

        for (0..gregorian.days_per_week) |week_day_index| {
            const month_day_index = week_index * gregorian.days_per_week + week_day_index;
            if (month_day_index >= days_in_month) {
                break;
            }

            try shared.day(state, .{
                .epoch_day = .{ .day = @intCast(month_start_epoch_day.day + month_day_index) },
                .flexbox = box,
                .week_index = week_index,
            }, "{d}", .{month_day_index + 1});
        }
    }
}
