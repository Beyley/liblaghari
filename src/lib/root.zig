const std = @import("std");
const testing = std.testing;

pub const languages = @import("languages.zig");
pub const time = @import("time/time.zig");

pub const CMonth = u8;
pub const CDay = u16;
pub const CYear = i64;
pub const CEpoch = u64;
pub const CLanguage = u8;

comptime {
    _ = time.hekenic;
}
