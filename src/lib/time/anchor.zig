const std = @import("std");
const epoch = std.time.epoch;

const @"epoch_o'eaiaa" = @import("o'eaiaa.zig");
const epoch_hekenic = @import("hekenic.zig");
const epoch_martian = @import("martian.zig");

// Source: https://discord.com/channels/1284943477984989258/1289355465658204210/1356107840087003317
pub const hekenic = struct {
    // calculated from our anchor point (Oct 10th 2106)
    pub const days_from_epoch_to_point = 49_955;

    pub const time: epoch_hekenic.YearMonthDay = .{ .year = 86, .month = .sitye, .month_day_index = 45 - 1 }; // -1 for day -> index
};
// Source: https://discord.com/channels/1284943477984989258/1289355465658204210/1356107840087003317
pub const martian = struct {
    // calculated from our anchor point (Oct 10th 2106)
    pub const days_from_epoch_to_point = 49_955;

    pub const time: epoch_martian.YearDay = .{ .year = 64, .day_index = 80 - 1 }; // -1 for day -> index
};
// Source: https://discord.com/channels/1284943477984989258/1289355465658204210/1356181925857071126
pub const @"o'eaiaa" = struct {
    // calculated from our anchor point (Oct 30th 2106)
    pub const days_from_epoch_to_point = 49_975;

    // year before 2106 (the year with the anchor point) is a leap year
    // Source: https://discord.com/channels/1284943477984989258/1289355465658204210/1356356372580532375
    pub const leap_year_relative_to_anchor = -1;

    // assert leap years are aligned to a multiple of four..
    comptime {
        std.debug.assert(@mod(time.year + leap_year_relative_to_anchor, 4) == 0);
    }

    pub const time: @"epoch_o'eaiaa".YearMonthDay = .{ .year = -leap_year_relative_to_anchor + 136, .month = .@"a'aunga", .day_index = 8 - 1 }; // -1 for day -> index
};
