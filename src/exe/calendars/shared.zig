const std = @import("std");
const epoch = std.time.epoch;

const dvui = @import("dvui");

const colors = @import("../colors.zig");
const State = @import("../gui.zig").State;

pub const DayInfo = struct {
    epoch_day: epoch.EpochDay,
    normal_colour: dvui.Color,
    highlighted_colour: dvui.Color,
    text_colour: dvui.Color,
    week_index: usize,

    flexbox: *dvui.FlexBoxWidget,

    pub fn isDay(self: DayInfo, other: epoch.EpochDay) bool {
        return self.epoch_day.day == other.day;
    }
};

const day_size: dvui.Size = .{ .w = 65, .h = 65 };

pub fn week(week_index: usize) *dvui.FlexBoxWidget {
    const border: dvui.Rect = .all(1);

    return dvui.flexbox(@src(), .{
        .justify_content = .start,
        .border_collapse = border.topLeft(),
    }, .{
        .id_extra = week_index,
        .margin = .all(4),
    });
}

pub fn day(
    state: State,
    day_info: DayInfo,
    comptime format: [:0]const u8,
    args: anytype,
) !void {
    var outer_box = dvui.box(@src(), .{}, .{
        .id_extra = @as(u64, day_info.epoch_day.day) + std.math.maxInt(u47) + 1,
    });
    defer outer_box.deinit();

    const colour: dvui.Color =
        if (day_info.isDay(state.now.epoch_day))
            day_info.highlighted_colour
        else
            (if ((day_info.flexbox.col + day_info.flexbox.row + day_info.week_index) % 2 == 0)
                day_info.normal_colour
            else
                .transparent);

    var day_box = dvui.box(@src(), .{}, .{
        .id_extra = day_info.epoch_day.day,

        .margin = .all(0),
        .padding = .all(4),

        .border = .all(1),

        .min_size_content = day_size,
        .max_size_content = .size(day_size),

        .color_fill = colour,

        .background = true,
    });
    defer day_box.deinit();

    // day is clicked
    if (dvui.clicked(&day_box.wd, .{})) {}

    dvui.label(@src(), format, args, .{
        .style = .content,
        .color_text = day_info.text_colour,
    });
}
