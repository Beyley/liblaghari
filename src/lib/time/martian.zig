const std = @import("std");
const epoch = std.time.epoch;

const anchor = @import("anchor.zig");

pub const Year = i17;

pub const days_per_year = 780;

pub const Day = std.math.IntFittingRange(0, days_per_year);

pub const YearDay = struct {
    year: Year,
    day_index: Day,

    pub fn fromGregorianEpochDay(gregorian: epoch.EpochDay) YearDay {
        // align to the anchor point
        const days_since_anchor: i48 = @as(i48, gregorian.day) - anchor.martian.days_from_epoch_to_point + anchor.martian.time.totalDays();

        return .{
            .year = @intCast(@divFloor(days_since_anchor, days_per_year)),
            .day_index = @intCast(@abs(@rem(days_since_anchor, days_per_year))),
        };
    }

    pub fn totalDays(self: YearDay) i48 {
        return (@as(i48, self.year) * days_per_year) + self.day_index;
    }
};
