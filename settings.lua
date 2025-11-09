data:extend({
     {
        type = "int-setting",
        name = "sardine-trace-batch-size",
        setting_type = "runtime-global",
        default_value = 50,
        order = "a",
        minimum_value = 1
    },
    {
        type = "int-setting",
        name = "sardine-trace-tick-time",
        setting_type = "startup",
        default_value = 20,
        order = "ab",
        minimum_value = 1
    },
})