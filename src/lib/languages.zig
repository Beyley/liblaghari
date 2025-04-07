pub const Language = enum(u8) {
    solar = 0,
    martian = 1,
    neptunian = 2,
    future_solar = 3,
    @"formal_o'eaiaa" = 4,
    @"informal_o'eaiaa" = 5,
    english = 6,

    pub fn endonym(self: Language) [:0]const u8 {
        return switch (self) {
            .solar => "t2hp2r2 nya",
            .martian => "t2hp2r2 naq",
            .neptunian => "SHPRE YHG",
            .future_solar => "t2b2s nya",
            .@"formal_o'eaiaa" => "PUIATTAQ",
            .@"informal_o'eaiaa" => "opeaiaa",
            .english => "English",
        };
    }
};
