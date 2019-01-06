
local function on_init(event)
    game.print('game init start')
    if not global.init_done then
        local map_gen_settings = {}
        map_gen_settings.water = "small"
        map_gen_settings.cliff_settings = {cliff_elevation_interval = 22, cliff_elevation_0 = 22}
        map_gen_settings.autoplace_controls = {
            ["coal"] = {frequency = "high", size = "very-big", richness = "normal"},
            ["stone"] = {frequency = "high", size = "very-big", richness = "normal"},
            ["copper-ore"] = {frequency = "high", size = "very-big", richness = "normal"},
            ["iron-ore"] = {frequency = "high", size = "very-big", richness = "normal"},
            ["crude-oil"] = {frequency = "very-high", size = "very-big", richness = "normal"},
            ["trees"] = {frequency = "normal", size = "normal", richness = "normal"},
            ["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
            ["grass"] = {frequency = "normal", size = "normal", richness = "normal"},
            ["sand"] = {frequency = "normal", size = "normal", richness = "normal"},
            ["desert"] = {frequency = "normal", size = "normal", richness = "normal"},
            ["dirt"] = {frequency = "normal", size = "normal", richness = "normal"}
        }
        game.create_surface("survival_in_pollution", map_gen_settings)
        local surface = game.surfaces["survival_in_pollution"]

        local radius = 256
        game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})

        game.map_settings.enemy_expansion.enabled = true
        --game.map_settings.enemy_evolution.destroy_factor = 0
        --game.map_settings.enemy_evolution.time_factor = 0
        --game.map_settings.enemy_evolution.pollution_factor = 0

        global.init_done = true
        game.print('game init completed')
    end
end

local function on_player_joined_game(event)
    on_init(event)
    --if player.online_time < 1 then
    --    player.insert({name = "pistol", count = 1})
    --    player.insert({name = "iron-axe", count = 1})
    --    player.insert({name = "raw-fish", count = 3})
    --    player.insert({name = "firearm-magazine", count = 16})
    --    player.insert({name = "iron-plate", count = 32})
    --    if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
    --end
    --
    --local surface = game.surfaces["fish_defender"]
    --if player.online_time < 2 and surface.is_chunk_generated({0,0}) then
    --    player.teleport(surface.find_non_colliding_position("player", {-75, 4}, 50, 1), "fish_defender")
    --else
    --    if player.online_time < 2 then
    --        player.teleport({-50, 0}, "fish_defender")
    --    end
    --end

end

local event = require('utils.event')
--event.on_init(on_init)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
