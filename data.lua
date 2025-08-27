local sardine = table.deepcopy(data.raw["locomotive"]["locomotive"])
local sardineItem = table.deepcopy(data.raw["item-with-entity-data"]["locomotive"])
sardine.name = "MFZ-sardine"
sardine.minable.result = "MFZ-sardine"
sardineItem.name = "MFZ-sardine"
sardineItem.place_result = "MFZ-sardine"

local recipe = {
    type = "recipe",
    name = "MFZ-sardine",
    enabled = true,
    ingredients = {
        {type = "item", name = "locomotive", amount = 1}
    },
    results = {{type = "item", name = "MFZ-sardine", amount = 1}}
}

data:extend{sardineItem, sardine, recipe}