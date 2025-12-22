const std = @import("std");

const c = @import("c");
const laghari = @import("laghari");
const hekenic_time = laghari.time.hekenic;
const martian_time = laghari.time.martian;
const babbep_time = laghari.time.babbep;
const @"o'eaiaa_time" = laghari.time.@"o'eaiaa";
const zeit = @import("zeit");

const Commands = enum {
    date,
    time,
    time_test,
    now,
};

pub fn main() !void {
    const gpa = std.heap.smp_allocator;

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    var env_map = try std.process.getEnvMap(gpa);
    defer env_map.deinit();

    const command =
        if (args.len < 2)
            .now
        else
            (std.meta.stringToEnum(Commands, args[1]) orelse return error.UnknownCommand);

    var buf: [1024]u8 = undefined;
    var stdout_writer_impl = std.fs.File.stdout().writer(&buf);
    const out = &stdout_writer_impl.interface;

    const local_timezone = try zeit.local(gpa, &env_map);
    defer local_timezone.deinit();

    const babbep_timezone: zeit.TimeZone = .{
        .fixed = .{
            .name = "Babbep Local Time",
            .is_dst = false,
            .offset = -((5 * 60) + 14) * 60, // 5:14am is sunrise at summer solstice
        },
    };

    const now_local = try zeit.instant(.{
        .timezone = &local_timezone,
    });

    const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = @intCast(babbep_timezone.adjust(now_local.timezone.adjust(now_local.unixTimestamp()).timestamp).timestamp) };

    switch (command) {
        .date => {
            const DateType = enum {
                hekenic,
                martian,
                oeaiaa,
            };

            const date_type = std.meta.stringToEnum(DateType, args[2]) orelse return error.UnknownDateType;
            const language = std.meta.stringToEnum(laghari.languages.Language, args[3]) orelse return error.UnknownLanguage;
            const romanized = if (args.len > 4) (std.mem.eql(u8, args[4], "true")) else false;
            const year = if (args.len > 5) (std.mem.eql(u8, args[5], "true")) else true;

            const epoch_day = epoch_seconds.getEpochDay();

            switch (date_type) {
                .hekenic => {
                    const hekenic_year_month_day: hekenic_time.YearMonthDay = .fromGregorianEpochDay(epoch_day);

                    if (year)
                        try out.print("{d}, ", .{hekenic_year_month_day.year});

                    try out.print("{s}, {d}", .{
                        if (romanized)
                            hekenic_year_month_day.month.romanizedNameSafe(language)
                        else
                            hekenic_year_month_day.month.fontNameSafe(language),
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
            try printTestTime(out, epoch_seconds.secs);
            try printTestTime(out, 4316137200);
            try printTestTime(out, 4317865200);
            try printTestTime(out, 13562294400);
            try printTestTime(out, 1771747200);
            try printTestTime(out, 1741089600);
        },
        .now => {
            const epoch_day = epoch_seconds.getEpochDay();
            const hekenic_year_month_day: hekenic_time.YearMonthDay = .fromGregorianEpochDay(epoch_day);
            const martian_year_day: martian_time.YearDay = .fromGregorianEpochDay(epoch_day);
            const @"o'eaiaa_year_month_day": @"o'eaiaa_time".YearMonthDay = .fromGregorianEpochDay(epoch_day);
            const gregorian_year_day = epoch_day.calculateYearDay();
            const gregorian_month_day = gregorian_year_day.calculateMonthDay();

            const day_seconds = epoch_seconds.getDaySeconds();
            const day_ttyedde: babbep_time.DayTtyedde = .fromDaySeconds(day_seconds);

            try out.print("Date:  \t\tYear*\t(Month)\t\tDay\n", .{});
            try out.print("Gregorian:\t{d}\t{s}\t{d}\t{s}\n", .{
                gregorian_year_day.year,
                switch (gregorian_month_day.month) {
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
                gregorian_month_day.day_index + 1,
                if (std.time.epoch.isLeapYear(gregorian_year_day.year)) "(Leap Year!)" else "",
            });
            try out.print("Hekenic:\t{d}\t{s}\t\t{d}\n", .{
                hekenic_year_month_day.year,
                hekenic_year_month_day.month.fontName(.english) orelse return error.MissingLocalizedName,
                hekenic_year_month_day.day(),
            });
            try out.print("Martian:\t{d}\t\t\t{d}\n", .{ martian_year_day.year, martian_year_day.day() });
            try out.print("O'eaiā:\t\t{d}\t{s}\t\t{d}\t{s}\n", .{
                @"o'eaiaa_year_month_day".year,
                @"o'eaiaa_year_month_day".month.fontName(.english) orelse return error.MissingLocalizedName,
                @"o'eaiaa_year_month_day".day(),
                if (@"o'eaiaa_time".isLeapYear(@"o'eaiaa_year_month_day".year)) "(Leap Year!)" else "",
            });
            try out.print("\n", .{});
            try out.print("Time:\n", .{});
            try out.print("Bābbé̬p:\t{d}:{d}\n", .{ day_ttyedde.getDde(), day_ttyedde.getDdeTtyedde() });
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
