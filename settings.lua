settings = {}
settings["rents"] = {
    {
        ["coords"] = {
            ["marker"] = vec3(-240.0080, -991.0558, 28.2884), -- Example coordinates
            ["spawn"] = vec4(-250.7852, -998.5463, 29.3146, 249.8545),
            ["return"] = vec3(-250.9955, -1004.0247, 28.0073)
        },
        ["vehicles"] = {
            {
                ["name"] = "Blista",
                ["model"] = "blista",
                ["price"] = 100,
                ["caution"] = 1000
            },
            {
                ["name"] = "Buffalo",
                ["model"] = "buffalo",
                ["price"] = 200,
                ["caution"] = 1500
            }
        }
    }
}

settings["locales"] = {
    ["not_enough_money"] = "Nincs elég pénzed a jármű bérléshez.",
    ["rent_open"] = "Nyisd ki a bérlési menüt a ~INPUT_CONTEXT~ gombbal.",
    ["rent_return"] = "Vidd vissza a járművet a ~INPUT_CONTEXT~ gombbal.",
    ["blipname"] = "Jármü bérlés"
}
