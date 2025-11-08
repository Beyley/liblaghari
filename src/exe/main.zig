const std = @import("std");

const c = @import("c");
const laghari = @import("laghari");
const hekenic_time = laghari.time.hekenic;
const martian_time = laghari.time.martian;
const babbep_time = laghari.time.babbep;
const @"o'eaiaa_time" = laghari.time.@"o'eaiaa";

const Commands = enum {
    date,
    time,
    time_test,
};

pub fn main() !void {
    const gpa = std.heap.smp_allocator;

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const command = std.meta.stringToEnum(Commands, args[1]) orelse return error.UnknownCommand;

    var buf: [1024]u8 = undefined;
    var stdout_writer_impl = std.fs.File.stdout().writer(&buf);
    const out = &stdout_writer_impl.interface;

    var t: c.time_t = c.time(null);
    var lt: c.tm = .{};
    _ = c.localtime_r(&t, &lt);
    const raw_epoch_seconds: u64 = @intCast(std.time.timestamp() + lt.tm_gmtoff);

    switch (command) {
        .date => {
            const DateType = enum {
                hekenic,
                martian,
                oeaiaa,
            };

            const date_type = std.meta.stringToEnum(DateType, args[2]) orelse return error.UnknownDateType;
            const language = std.meta.stringToEnum(laghari.languages.Language, args[3]) orelse return error.UnknownLanguage;

            const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = raw_epoch_seconds };
            const epoch_day = epoch_seconds.getEpochDay();

            switch (date_type) {
                .hekenic => {
                    const hekenic_year_month_day: hekenic_time.YearMonthDay = .fromGregorianEpochDay(epoch_day);

                    try out.print("{d},{?s},{d}", .{
                        hekenic_year_month_day.year,
                        hekenic_year_month_day.month.fontName(language),
                        hekenic_year_month_day.day(),
                    });
                },
                .martian => {
                    const martian_year_day: martian_time.YearDay = .fromGregorianEpochDay(epoch_day);

                    try out.print("{d}, {d}", .{ martian_year_day.year, martian_year_day.day() });
                },
                .oeaiaa => {
                    const year_month_day: @"o'eaiaa_time".YearMonthDay = .fromGregorianEpochDay(epoch_day);

                    try out.print("{d}, {d} {s}", .{
                        year_month_day.year,
                        year_month_day.day(),
                        year_month_day.month.fontName(language) orelse return error.MissingLocalizedName,
                    });
                },
            }
        },
        .time => {
            const ClockType = enum {
                babbep,
            };

            const clock_type = std.meta.stringToEnum(ClockType, args[2]) orelse return error.UnknownClockType;

            const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = raw_epoch_seconds };
            const day_seconds = epoch_seconds.getDaySeconds();

            switch (clock_type) {
                .babbep => {
                    const day_ttyedde: babbep_time.DayTtyedde = .fromDaySeconds(day_seconds);

                    try out.print("{d}:{d}", .{ day_ttyedde.getDde(), day_ttyedde.getDdeTtyedde() });
                },
            }
        },
        .time_test => {
            try printTestTime(out, 0);
            try printTestTime(out, raw_epoch_seconds);
            try printTestTime(out, 4316137200);
            try printTestTime(out, 4317865200);
            try printTestTime(out, 13562294400);
            try printTestTime(out, 1771747200);
        },
    }

    try out.flush();
}

fn printTestTime(writer: anytype, secs: u64) !void {
    const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = secs };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    const hekenic_year_month_day: hekenic_time.YearMonthDay = .fromGregorianEpochDay(epoch_day);
    const martian_year_day: martian_time.YearDay = .fromGregorianEpochDay(epoch_day);
    const @"o'eaiaa_year_day": @"o'eaiaa_time".YearMonthDay = .fromGregorianEpochDay(epoch_day);

    try writer.print("Gregorian: {d}, {s} {d}\n", .{ year_day.year, @tagName(month_day.month), month_day.day_index + 1 });
    try writer.print("Hekenic: {d}, {s} {d}      {d}\n", .{ hekenic_year_month_day.year, @tagName(hekenic_year_month_day.month), hekenic_year_month_day.day(), hekenic_year_month_day.toGregorianEpochDay().day });
    try writer.print("Martian: {d}, {d}\n", .{ martian_year_day.year, martian_year_day.day_index + 1 });
    try writer.print("O'eaiā: {d}, {s} {d}", .{ @"o'eaiaa_year_day".year, @tagName(@"o'eaiaa_year_day".month), @"o'eaiaa_year_day".day() });
    if (@"o'eaiaa_time".isLeapYear(@"o'eaiaa_year_day".year))
        try writer.print(" (leap year!)", .{});
    try writer.print("\n\n", .{});
}
