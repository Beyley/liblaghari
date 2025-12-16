const std = @import("std");
const epoch = std.time.epoch;

const dvui = @import("dvui");

const colors = @import("../colors.zig");
const State = @import("../gui.zig").State;

pub const DayInfo = struct {
    epoch_day: epoch.EpochDay,
    last_day_in_row: bool,
    normal_colour: dvui.Color,
    highlighted_colour: dvui.Color,
    text_colour: dvui.Color,

    pub fn isDay(self: DayInfo, other: epoch.EpochDay) bool {
        return self.epoch_day.day == other.day;
    }
};

const day_size: dvui.Size = .{ .w = 65, .h = 65 };

pub fn day(state: State, day_info: DayInfo, comptime format: [:0]const u8, args: anytype) !void {
    const colour: dvui.Color = if (day_info.isDay(state.now.epoch_day)) day_info.highlighted_colour else day_info.normal_colour;

    var day_box = dvui.box(@src(), .{}, .{
        .id_extra = day_info.epoch_day.day,

        .margin = if (day_info.last_day_in_row) .all(0) else .{ .w = -1, .h = -1 },
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
