const std = @import("std");

const laghari = @import("laghari");
const hekenic_time = laghari.time.hekenic;
const martian_time = laghari.time.martian;

pub fn main() !void {
    printTime(0);
    printTime(@intCast(std.time.timestamp()));
    printTime(4316137200);
    printTime(13551001200);
    printTime(1771747200);
}

fn printTime(secs: u64) void {
    const epoch_seconds: std.time.epoch.EpochSeconds = .{ .secs = secs };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    const hekenic_year_month_day: hekenic_time.YearMonthDay = .fromGregorianEpochDay(epoch_day);
    const martian_year_day: martian_time.YearDay = .fromGregorianEpochDay(epoch_day);

    std.debug.print("Gregorian: {d}, {s} {d}\n", .{ year_day.year, @tagName(month_day.month), month_day.day_index + 1 });
    std.debug.print("Hekenic: {d}, {s} {d}\n", .{ hekenic_year_month_day.year, @tagName(hekenic_year_month_day.month), hekenic_year_month_day.day() });
    std.debug.print("Martian: {d}, {d}\n", .{ martian_year_day.year, martian_year_day.day_index + 1 });
}
