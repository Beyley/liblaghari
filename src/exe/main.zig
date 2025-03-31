const std = @import("std");

const laghari = @import("laghari");
const hekenic_time = laghari.time.hekenic;
const martian_time = laghari.time.martian;

const Commands = enum {
    now,
    time_test,
};

pub fn main() !void {
    const gpa = std.heap.smp_allocator;

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const command = std.meta.stringToEnum(Commands, args[1]) orelse return error.UnknownCommand;

    const stdout = std.io.getStdOut();
    var buffered_stdout = std.io.bufferedWriter(stdout.writer());

    switch (command) {
        .now => {
            const DateType = enum {
                hekenic,
                martian,
            };

            const date_type = std.meta.stringToEnum(DateType, args[2]) orelse return error.UnknownDateType;
            const language = std.meta.stringToEnum(laghari.languages.Language, args[3]) orelse return error.UnknownLanguage;

            const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = @intCast(std.time.timestamp()) };
            const epoch_day = epoch_seconds.getEpochDay();

            switch (date_type) {
                .hekenic => {
                    const hekenic_year_month_day: hekenic_time.YearMonthDay = .fromGregorianEpochDay(epoch_day);

                    try buffered_stdout.writer().print("{d},{?s},{d}", .{
                        hekenic_year_month_day.year,
                        hekenic_year_month_day.month.localizedName(language),
                        hekenic_year_month_day.day(),
                    });
                },
                .martian => {
                    const martian_year_day: martian_time.YearDay = .fromGregorianEpochDay(epoch_day);

                    try buffered_stdout.writer().print("{d}, {d}", .{ martian_year_day.year, martian_year_day.day() });
                },
            }
        },
        .time_test => {
            try printTestTime(buffered_stdout.writer(), 0);
            try printTestTime(buffered_stdout.writer(), @intCast(std.time.timestamp()));
            try printTestTime(buffered_stdout.writer(), 4316137200);
            try printTestTime(buffered_stdout.writer(), 13551001200);
            try printTestTime(buffered_stdout.writer(), 1771747200);
        },
    }

    try buffered_stdout.flush();
}

fn printTestTime(writer: anytype, secs: u64) !void {
    const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = secs };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    const hekenic_year_month_day: hekenic_time.YearMonthDay = .fromGregorianEpochDay(epoch_day);
    const martian_year_day: martian_time.YearDay = .fromGregorianEpochDay(epoch_day);

    try writer.print("Gregorian: {d}, {s} {d}\n", .{ year_day.year, @tagName(month_day.month), month_day.day_index + 1 });
    try writer.print("Hekenic: {d}, {s} {d}\n", .{ hekenic_year_month_day.year, @tagName(hekenic_year_month_day.month), hekenic_year_month_day.day() });
    try writer.print("Martian: {d}, {d}\n", .{ martian_year_day.year, martian_year_day.day_index + 1 });
}
