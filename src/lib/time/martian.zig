const std = @import("std");
const epoch = std.time.epoch;

const root = @import("../root.zig");
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

    pub fn toGregorianEpochDay(self: YearDay) epoch.EpochDay {
        const days_since_anchor = self.totalDays() - anchor.martian.time.totalDays();

        return .{ .day = @intCast(anchor.hekenic.days_from_epoch_to_point + days_since_anchor) };
    }

    pub fn totalDays(self: YearDay) i48 {
        return (@as(i48, self.year) * days_per_year) + self.day_index;
    }

    pub fn day(self: YearDay) Day {
        return self.day_index + 1;
    }
};

pub export fn laghariMartianYearFromGregorian(gregorian: root.CEpoch) root.CYear {
    const year_month_day: YearDay = .fromGregorianEpochDay(.{ .day = @intCast(gregorian) });

    return year_month_day.year;
}

pub export fn laghariMartianDayFromGregorian(gregorian: root.CEpoch) root.CDay {
    const year_month_day: YearDay = .fromGregorianEpochDay(.{ .day = @intCast(gregorian) });

    return year_month_day.day();
}

pub export fn laghariMartianToGregorianEpoch(year: root.CYear, day: root.CDay) root.CEpoch {
    const year_month_day: YearDay = .{ .day_index = @intCast(day), .year = @intCast(year) };

    return year_month_day.toGregorianEpochDay().day;
}
