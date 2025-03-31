const std = @import("std");
const epoch = std.time.epoch;

const languages = @import("../languages.zig");
const anchor = @import("anchor.zig");

pub const Year = i17;

pub const Day = std.math.IntFittingRange(0, days_per_year - 1); // make it exclusive

pub const days_per_year = 364;

pub const Month = enum {
    // month of reverence, holiday
    alikakaela,
    // month 1
    angaru,
    // month 2
    higaama,
    // month 3
    @"a'aunga",
    // month 4
    ilizaana,
    // month 5
    ukuarii,
    // month 6
    hashasanga,

    pub fn days(self: Month) Day {
        return switch (self) {
            .alikakaela => 10,
            .angaru,
            .higaama,
            .@"a'aunga",
            .ilizaana,
            .ukuarii,
            .hashasanga,
            => 59,
        };
    }
};

pub const MonthAndDay = struct {
    month: Month,
    day: Day,
};

pub const YearMonthDay = struct {
    year: Year,
    month: Month,
    day_index: Day,

    pub fn fromGregorianEpochDay(gregorian: epoch.EpochDay) YearMonthDay {
        // align to the anchor point
        const days_since_anchor: i48 = @as(i48, gregorian.day) - anchor.@"o'eaiaa".days_from_epoch_to_point + anchor.@"o'eaiaa".time.totalDays();

        const year_day_index = @abs(@rem(days_since_anchor, days_per_year));

        const short_month_days = Month.alikakaela.days();
        const long_month_days = 59;

        const month: Month, const day_index: u9 =
            if (year_day_index < short_month_days)
                .{ .alikakaela, @intCast(year_day_index) }
            else
                .{
                    @enumFromInt(@divFloor(year_day_index - short_month_days, long_month_days) + 1),
                    @intCast(@mod(year_day_index - short_month_days, long_month_days)),
                };

        return .{
            .year = @intCast(@divFloor(days_since_anchor, days_per_year)),
            .month = month,
            .day_index = day_index,
        };
    }

    pub fn totalDays(self: YearMonthDay) i48 {
        var month_days: u47 = 0;
        for (std.enums.values(Month)[0..@intFromEnum(self.month)]) |month|
            month_days += month.days();

        return self.day_index + month_days + (@as(i48, self.year) * days_per_year);
    }

    pub fn day(self: YearMonthDay) Day {
        return self.day_index + 1;
    }
};
