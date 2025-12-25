pub const @"o'eaiā" = @import("o'eaiaa.zig");
pub const gregorian = @import("gregorian.zig");
pub const hekenic = @import("hekenic.zig");
pub const martian = @import("martian.zig");

pub const Calendar = enum {
    gregorian,
    hekenic,
    martian,
    @"o'eaiā",
};
