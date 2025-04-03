const std = @import("std");
const epoch = std.time.epoch;

const languages = @import("../languages.zig");
const root = @import("../root.zig");
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

    pub fn toGregorianEpochDay(self: YearMonthDay) epoch.EpochDay {
        const days_since_anchor = self.totalDays() - anchor.hekenic.time.totalDays();

        return .{ .day = @intCast(anchor.hekenic.days_from_epoch_to_point + days_since_anchor) };
    }

    pub fn totalDays(self: YearMonthDay) i48 {
        return self.day_index + (@intFromEnum(self.month) * @as(i48, days_per_month)) + (@as(i48, self.year) * days_per_year);
    }

    pub fn day(self: YearMonthDay) Day {
        return self.day_index + (@intFromEnum(self.month) * @as(Day, days_per_month)) + 1;
    }
};

pub export fn laghariHekenicYearFromGregorian(gregorian: root.CEpoch) root.CDay {
    const year_month_day: YearMonthDay = .fromGregorianEpochDay(.{ .day = @intCast(gregorian) });

    return year_month_day.year;
}

pub export fn laghariHekenicMonthFromGregorian(gregorian: root.CEpoch) root.CMonth {
    const year_month_day: YearMonthDay = .fromGregorianEpochDay(.{ .day = @intCast(gregorian) });

    return @intFromEnum(year_month_day.month);
}

pub export fn laghariHekenicDayFromGregorian(gregorian: root.CEpoch) root.CDay {
    const year_month_day: YearMonthDay = .fromGregorianEpochDay(.{ .day = @intCast(gregorian) });

    return year_month_day.day();
}

pub export fn laghariHekenicMonthDayFromGregorian(gregorian: root.CEpoch) root.CDay {
    const year_month_day: YearMonthDay = .fromGregorianEpochDay(.{ .day = @intCast(gregorian) });

    return year_month_day.day_index + 1;
}

pub export fn laghariHekenicToGregorianEpoch(year: root.CYear, c_month: root.CMonth, day: root.CDay) root.CEpoch {
    const month = std.meta.intToEnum(Month, c_month) catch return -1;

    const year_month_day: YearMonthDay = .{ .day_index = @intCast(day), .month = month, .year = @intCast(year) };

    return year_month_day.toGregorianEpochDay().day;
}

pub export fn laghariHekenicMonthFontNamePtr(c_month: root.CMonth, c_language: root.CLanguage) ?[*:0]const u8 {
    const month = std.meta.intToEnum(Month, c_month) catch return null;
    const language: languages.Language = std.meta.intToEnum(languages.Language, c_language) catch return null;

    const font_name = month.fontName(language);

    if (font_name) |font_name_slice|
        return font_name_slice.ptr
    else
        return null;
}

pub export fn laghariHekenicMonthFontNameLen(c_month: root.CMonth, c_language: root.CLanguage) i32 {
    const month = std.meta.intToEnum(Month, c_month) catch return -1;
    const language: languages.Language = std.meta.intToEnum(languages.Language, c_language) catch return -1;

    const font_name = month.fontName(language);

    if (font_name) |font_name_slice|
        return @intCast(font_name_slice.len)
    else
        return -1;
}
