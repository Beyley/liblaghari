const std = @import("std");
const epoch = std.time.epoch;

const languages = @import("../languages.zig");
const anchor = @import("anchor.zig");

pub const Year = i17;

pub const Day = std.math.IntFittingRange(0, days_per_year - 1); // make it exclusive

pub const days_per_month = 116;
pub const days_per_year = 116 * 5;

pub const Month = enum {
    /// Month 1
    sii,
    /// Month 2
    sitye,
    /// Month 3
    sichi,
    /// Month 4
    sihe,
    /// Month 5
    siyem,

    pub fn fontName(self: Month, language: languages.Language) ?[:0]const u8 {
        return switch (language) {
            .solar => switch (self) {
                .sii => "trihfi",
                .sitye => "trihtyei",
                .sichi => "trihtri",
                .sihe => "trihi",
                .siyem => "trihyeim",
            },
            .martian => switch (self) {
                .sii => "cih2",
                .sitye => "cihty2",
                .sichi => "cihci",
                .sihe => "cihi",
                .siyem => "cihy2m",
            },
            .neptunian => switch (self) {
                .sii => "CIFE",
                .sitye => "CICE",
                .sichi => "CICI",
                .sihe => "CIHI",
                .siyem => "CIYEM",
            },
            .future_solar => null, // no data available
            .@"o'eaiaa" => null, // no data avaialable
        };
    }
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
