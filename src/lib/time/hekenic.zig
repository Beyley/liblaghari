const std = @import("std");
const epoch = std.time.epoch;

const anchor = @import("anchor.zig");

pub const Year = i17;

pub const Day = std.math.IntFittingRange(0, days_per_year - 1); // make it exclusive

pub const days_per_month = 116;
pub const days_per_year = 116 * 5;

pub const Month = enum(std.math.IntFittingRange(0, 4)) {
    /// Month 1
    sii = 0,
    /// Month 2
    sitye = 1,
    /// Month 3
    sichi = 2,
    /// Month 4
    sihe = 3,
    /// Month 5
    siyem = 4,
};

pub const MonthAndDay = struct {
    month: Month,
    day_index: Day,

    pub fn toYearDay(self: MonthAndDay) Day {
        return @intFromEnum(self.month) * days_per_month + self.day_index;
    }

    pub fn fromYearDay(year_day_index: Day) MonthAndDay {
        std.debug.assert(year_day_index < days_per_year);

        return .{
            .month = @enumFromInt(@divFloor(year_day_index, days_per_month)),
            .day_index = @intCast(year_day_index % days_per_month),
        };
    }

    pub fn fromYearMonthDay(year_month_day: YearMonthDay) MonthAndDay {
        return .{
            .month = year_month_day.month,
            .day_index = year_month_day.day_index,
        };
    }
};

pub const YearMonthDay = struct {
    year: Year,
    month: Month,
    day_index: Day,

    pub fn fromGregorianEpochDay(gregorian: epoch.EpochDay) YearMonthDay {
        // align to the anchor point
        const days_since_anchor: i48 = @as(i48, gregorian.day) - anchor.hekenic.days_from_epoch_to_point + anchor.hekenic.time.totalDays();

        const month_and_day: MonthAndDay = .fromYearDay(@intCast(@abs(@rem(days_since_anchor, days_per_year))));

        return .{
            .year = @intCast(@divFloor(days_since_anchor, days_per_year)),
            .month = month_and_day.month,
            .day_index = month_and_day.day_index,
        };
    }

    pub fn totalDays(self: YearMonthDay) i48 {
        return self.day_index + (@intFromEnum(self.month) * @as(i48, days_per_month)) + (@as(i48, self.year) * days_per_year);
    }

    pub fn day(self: YearMonthDay) Day {
        return self.day_index + (@intFromEnum(self.month) * @as(Day, days_per_month)) + 1;
    }
};
