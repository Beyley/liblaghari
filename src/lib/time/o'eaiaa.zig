const std = @import("std");
const epoch = std.time.epoch;

const languages = @import("../languages.zig");
const anchor = @import("anchor.zig");

pub const Year = i17;

const max_days_per_year = 366;

pub const Day = std.math.IntFittingRange(0, 366); // make it exclusive

// source: https://discord.com/channels/1284943477984989258/1289355465658204210/1356301947564593223
// Video shows alikakaela having 10 days, corrected by ZeWei to be 11 days
const short_month_days = 11;
const long_month_days = 59;

// leap years happen every 4 years, with the last leap year happening the O'eaiaa year before the gregorian date 2106, Oct 30
pub fn isLeapYear(year: Year) bool {
    return @rem(year, 4) == 0;
}

test "leap years" {
    std.testing.expect(isLeapYear(0));
    std.testing.expect(isLeapYear(4));
    std.testing.expect(isLeapYear(2000));
    std.testing.expect(isLeapYear(-12));
    std.testing.expect(!isLeapYear(2001));
    std.testing.expect(!isLeapYear(1));
    std.testing.expect(!isLeapYear(3));
    std.testing.expect(!isLeapYear(-2));
    std.testing.expect(!isLeapYear(-11));
}

pub fn daysInYear(year: Year) Day {
    return if (isLeapYear(year)) max_days_per_year else max_days_per_year - 1;
}

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

    pub fn days(self: Month, year: Year) Day {
        return switch (self) {
            .alikakaela => if (isLeapYear(year)) short_month_days + 1 else short_month_days,
            .angaru,
            .higaama,
            .@"a'aunga",
            .ilizaana,
            .ukuarii,
            .hashasanga,
            => long_month_days,
        };
    }

    pub fn fontNameSafe(self: Month, language: languages.Language) [:0]const u8 {
        return self.fontName(language) orelse self.fontName(.english) orelse @tagName(self);
    }

    pub fn fontName(self: Month, language: languages.Language) ?[:0]const u8 {
        return switch (language) {
            .@"formal_o'eaiaa" => switch (self) {
                .alikakaela => "TAIKAKKAIAQ",
                .angaru => "KAUATUU",
                .higaama => "QIQIAAP",
                .@"a'aunga" => "PAAUQUAU",
                .ilizaana => "TIITQAUT",
                .ukuarii => "KUUATIIK",
                .hashasanga => "TIAAPQAT",
            },
            .@"informal_o'eaiaa" => switch (self) {
                .alikakaela => "alikakaela",
                .angaru => "angatu",
                .higaama => "higaama",
                .@"a'aunga" => "apaunga",
                .ilizaana => "ilizaana",
                .ukuarii => "ukuatii",
                .hashasanga => "hata:lasanga",
            },
            .english => switch (self) {
                .alikakaela => "Alikakaela",
                .angaru => "Angaru",
                .higaama => "Higāma",
                .@"a'aunga" => "A'aunga",
                .ilizaana => "Ilizāna",
                .ukuarii => "Ukuarī",
                .hashasanga => "Hashasanga",
            },
            // no data
            .solar => null,
            .martian => null,
            .neptunian => null,
            .future_solar => null,
        };
    }
};

pub const MonthAndDay = struct {
    month: Month,
    day_index: Day,

    pub fn fromDayIndex(day_index: Day, year: Year) MonthAndDay {
        std.debug.assert(day_index < daysInYear(year));

        var day_total = day_index;
        var month_index: std.meta.Tag(Month) = 0;
        for (std.enums.values(Month)) |month| {
            const days_in_month = month.days(year);

            if (days_in_month > day_total)
                break;

            day_total -= days_in_month;
            month_index += 1;
        }

        return .{
            .day_index = day_total,
            .month = @enumFromInt(month_index),
        };
    }

    pub fn day(self: MonthAndDay) Day {
        return self.day_index - 1;
    }
};

pub const YearMonthDay = struct {
    year: Year,
    month: Month,
    month_day_index: Day,

    pub fn fromGregorianEpochDay(gregorian: epoch.EpochDay) YearMonthDay {
        // calculate how many days have passed since the epoch
        const days_since_anchor: i48 = @as(i48, gregorian.day) - anchor.@"o'eaiā".days_from_epoch_to_point;

        // we are on the anchor day
        if (days_since_anchor == 0)
            return anchor.@"o'eaiā".time;

        var year: Year = anchor.@"o'eaiā".time.year;
        var day_index = days_since_anchor + anchor.@"o'eaiā".time.yearDayIndex();

        // future
        while (day_index >= daysInYear(year)) {
            day_index -= daysInYear(year);
            year += 1;
        }

        // past
        while (day_index < 0) {
            year -= 1;
            day_index += daysInYear(year);
        }

        const month_and_day: MonthAndDay = .fromDayIndex(@intCast(day_index), year);

        return .{
            .year = year,
            .month = month_and_day.month,
            .month_day_index = month_and_day.day_index,
        };
    }

    pub fn toGregorianEpochDay(self: YearMonthDay) epoch.EpochDay {
        const offset_from_anchor = self.totalDays() - anchor.@"o'eaiā".time.totalDays();

        return .{ .day = @intCast(anchor.@"o'eaiā".days_from_epoch_to_point + offset_from_anchor) };
    }

    pub fn totalDays(self: YearMonthDay) i48 {
        var year_days: i48 = 0;
        for (0..@abs(self.year)) |year|
            year_days += daysInYear(@intCast(year));

        var month_days: u47 = 0;
        for (std.enums.values(Month)[0..@intFromEnum(self.month)]) |month|
            month_days += month.days(self.year);

        return self.month_day_index + month_days + year_days;
    }

    pub fn yearStart(self: YearMonthDay) YearMonthDay {
        return .{
            .month_day_index = 0,
            .month = .alikakaela,
            .year = self.year,
        };
    }

    pub fn monthDay(self: YearMonthDay) Day {
        return self.month_day_index + 1;
    }

    pub fn yearDayIndex(self: YearMonthDay) i48 {
        var month_days: u47 = 0;
        for (std.enums.values(Month)[0..@intFromEnum(self.month)]) |month|
            month_days += month.days(self.year);

        return month_days + self.month_day_index;
    }
};
