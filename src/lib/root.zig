const std = @import("std");
const testing = std.testing;

pub const languages = @import("languages.zig");
pub const time = @import("time/time.zig");

// these are the only types supported officially by wasm
pub const CMonth = i32;
pub const CDay = i32;
pub const CYear = i64;
pub const CEpoch = i64;
pub const CLanguage = i32;

comptime {
    _ = time.hekenic;
}
