const std = @import("std");
const epoch = std.time.epoch;

const languages = @import("../languages.zig");
const root = @import("../root.zig");
const anchor = @import("anchor.zig");

pub const Year = u16;

pub const Day = std.math.IntFittingRange(0, max_days_per_year - 1); // make it exclusive

pub const max_days_per_year = 366;
pub const days_per_week = 7;

pub const months_per_year: comptime_int = std.meta.tags(Month).len;

pub const Month = enum {
    jan,
    feb,
    mar,
    apr,
    may,
    jun,
    jul,
    aug,
    sep,
    oct,
    nov,
    dec,

    pub fn fontNameSafe(self: Month, language: languages.Language) [:0]const u8 {
        return self.fontName(language) orelse self.fontName(.english) orelse @tagName(self);
    }

    pub fn fontName(self: Month, language: languages.Language) ?[:0]const u8 {
        return switch (language) {
            .solar => null, // no data
            .martian => null, // no data
            .neptunian => null, // no data
            .future_solar => null, // no data
            .@"formal_o'eaiaa" => null, // no data
            .@"informal_o'eaiaa" => null, // no data
            .english => switch (self) {
                .jan => "January",
                .feb => "February",
                .mar => "March",
                .apr => "April",
                .may => "May",
                .jun => "June",
                .jul => "July",
                .aug => "August",
                .sep => "September",
                .oct => "October",
                .nov => "November",
                .dec => "December",
            },
        };
    }

    pub fn daysInMonth(self: Month, year: Year) Day {
        return switch (self) {
            .jan => 31,
            .feb => @as(u5, switch (epoch.isLeapYear(year)) {
                true => 29,
                false => 28,
            }),
            .mar => 31,
            .apr => 30,
            .may => 31,
            .jun => 30,
            .jul => 31,
            .aug => 31,
            .sep => 30,
            .oct => 31,
            .nov => 30,
            .dec => 31,
        };
    }
};

pub const YearMonthDay = struct {
    year: Year,
    month: Month,
    month_day_index: Day,

    pub fn fromEpochDay(day: epoch.EpochDay) YearMonthDay {
        const year_day = day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();

        return .{
            .year = year_day.year,
            .month = switch (month_day.month) {
                inline else => |month| comptime @field(Month, @tagName(month)),
            },
            .month_day_index = month_day.day_index,
        };
    }

    pub fn toEpochDay(self: YearMonthDay) epoch.EpochDay {
        // TODO: return proper error
        std.debug.assert(self.year >= epoch.epoch_year);

        var epoch_day: epoch.EpochDay = .{ .day = 0 };
        for (epoch.epoch_year..self.year) |year| {
            epoch_day.day += epoch.getDaysInYear(@intCast(year));
        }

        for (0..@intFromEnum(self.month)) |month_idx| {
            epoch_day.day += @as(Month, @enumFromInt(month_idx)).daysInMonth(self.year);
        }

        epoch_day.day += self.month_day_index;

        return epoch_day;
    }

    pub fn toEpochSeconds(self: YearMonthDay) epoch.EpochSeconds {
        return .{
            .secs = @as(u64, self.toEpochDay().day) * std.time.epoch.secs_per_day,
        };
    }

    pub fn monthStart(self: YearMonthDay) YearMonthDay {
        return .{
            .year = self.year,
            .month = self.month,
            .month_day_index = 0,
        };
    }
};
