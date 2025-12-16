const std = @import("std");
const epoch = std.time.epoch;

const dvui = @import("dvui");

const State = @import("../gui.zig").State;

pub const DayInfo = struct {
    epoch_day: epoch.EpochDay,
};

const day_size: dvui.Size = .{ .w = 65, .h = 65 };

pub fn day(state: State, day_info: DayInfo, comptime format: [:0]const u8, args: anytype) !void {
    var day_box = dvui.box(@src(), .{}, .{
        .id_extra = day_info.epoch_day.day,

        .margin = .all(4),
        .padding = .all(4),

        .min_size_content = day_size,
        .max_size_content = .size(day_size),

        .color_fill = if (day_info.epoch_day.day == state.now.epoch_day.day) .gray else dvui.Color.gray.lighten(-50),

        // .corner_radius = corner_radius,

        .background = true,
    });
    defer day_box.deinit();

    dvui.label(@src(), format, args, .{
        .style = .content,
    });
}
