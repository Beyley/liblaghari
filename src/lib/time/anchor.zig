const std = @import("std");
const epoch = std.time.epoch;

const epoch_hekenic = @import("hekenic.zig");
const epoch_martian = @import("martian.zig");

// Source: https://discord.com/channels/1284943477984989258/1289355465658204210/1356107840087003317
pub const hekenic = struct {
    pub const days_from_epoch_to_point = 49_955;

    pub const time: epoch_hekenic.YearMonthDay = .{ .year = 86, .month = .sitye, .day_index = 45 - 1 }; // -1 for day -> index
};
pub const martian = struct {
    pub const days_from_epoch_to_point = 49_955;

    pub const time: epoch_martian.YearDay = .{ .year = 64, .day_index = 80 - 1 }; // -1 for day -> index
};
