const std = @import("std");
const epoch = std.time.epoch;

pub const dde_per_day = 10;
pub const ttyedde_per_dde = 10;
pub const ttyedde_per_day = dde_per_day * ttyedde_per_dde;

const seconds_per_ttyedde = epoch.secs_per_day / ttyedde_per_day;
const seconds_per_dde = epoch.secs_per_day / dde_per_day;

// Represents amount of Ttyedde into a day.
pub const DayTtyedde = struct {
    ttyedde: std.math.IntFittingRange(0, ttyedde_per_day),

    pub fn fromDaySeconds(day_seconds: epoch.DaySeconds) DayTtyedde {
        return .{
            .ttyedde = @intCast(@divTrunc(day_seconds.secs, (seconds_per_ttyedde))),
        };
    }

    pub fn getDde(self: DayTtyedde) std.math.IntFittingRange(0, dde_per_day) {
        return @intCast(@divTrunc(self.ttyedde, ttyedde_per_dde));
    }

    pub fn getDdeTtyedde(self: DayTtyedde) std.math.IntFittingRange(0, ttyedde_per_dde) {
        return @intCast(self.ttyedde % ttyedde_per_dde);
    }
};
