local default = data.raw["gui-style"].default

default["sardine-frame"] = {
    type = "frame_style",
    parent = "frame",
    minimal_height=256,
    maximal_height=2048,
    minimal_width=320,
    maximal_width=770,
    --width = 385,
    natural_width = 320,
    natural_height = 256, --Make sure to use natural height when defining stretchaable elements.
    vertically_stretchable = "on",
    horizontally_stretchable = "on"
}

default["sardine-main-vflow"] = {
    type="vertical_flow_style",
    parent="vertical_flow",
    minimal_height=32,
    natural_height=32,
    vertically_stretchable="on"
}

default["sardine-inner-frame"] = {
    type="frame_style",
    parent="inside_shallow_frame_with_padding",
    minimal_height=32,
    natural_height=32,
    minimal_width = 300,
    maximal_width = 750,
    vertically_stretchable="on",
    horizontally_stretchable="on",
    vertical_flow_style={
        type="vertical_flow_style",
        parent="vertical_flow",
        vertical_spacing=6
    }
}

default["sardine-cost-frame"] = {
    type="scroll_pane_style",
    parent="deep_slots_scroll_pane",
    width=320
}

default["sardine-cost-row"] = {
    type="horizontal_flow_style",
    parent="horizontal_flow",
    width=320,
    horizontal_spacing=0
}

default["sardine-bottom-hflow"] = {
    type="horizontal_flow_style",
    parent="horizontal_flow",
    horizontally_stretchable="on",
    horizontal_align="right",
    height=34
}

default["sardine-status-hflow"] = {
    type="horizontal_flow_style",
    parent="horizontal_flow",
    horizontally_stretchable="on",
    horizontal_align="left",
    height=34,
    vertical_align="center"
}