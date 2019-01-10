require 'stdlib/event/event'

INIT_PHASE_CREATE_SURFACE = 1
INIT_PHASE_SET_SPAWN = 2
INIT_PHASE_COMPLETED = -1

local function delete_other_surfaces()
    -- cannot delete the default surface!!! why?
    for _, surface in pairs(game.surfaces) do
        if surface.name ~= SURVIVAL_IN_POLLUTION then
            game.print("delete surface " .. surface.name)
            game.delete_surface(surface)
        end
    end
end

local function init_map_gen_settings()
    local map_gen_settings = {}
    map_gen_settings.water = "small"
    map_gen_settings.cliff_settings = {cliff_elevation_interval = 22, cliff_elevation_0 = 22}
    map_gen_settings.autoplace_controls = {
        ["coal"] = {frequency = "very-low", size = "very-big", richness = "good"},
        ["stone"] = {frequency = "very-low", size = "big", richness = "normal"},
        ["copper-ore"] = {frequency = "very-low", size = "very-big", richness = "very-good"},
        ["iron-ore"] = {frequency = "very-low", size = "very-big", richness = "very-good"},
        ["crude-oil"] = {frequency = "very-low", size = "small", richness = "very-poor"},
        ["trees"] = {frequency = "normal", size = "normal", richness = "very-good"},
        ["enemy-base"] = {frequency = "low", size = "very-big", richness = "very-good"},
        ["grass"] = {frequency = "normal", size = "normal", richness = "normal"},
        ["sand"] = {frequency = "normal", size = "normal", richness = "normal"},
        ["desert"] = {frequency = "normal", size = "normal", richness = "normal"},
        ["dirt"] = {frequency = "normal", size = "normal", richness = "normal"}
    }
    return map_gen_settings
end


local function create_surface()
    local map_gen_settings = init_map_gen_settings()
    game.create_surface(SURVIVAL_IN_POLLUTION, map_gen_settings)
    return game.surfaces[SURVIVAL_IN_POLLUTION]
end

local function view_starting_area(surface)
    local radius = 256
    game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
end

local function init_map_settings()
    game.map_settings.enemy_expansion.enabled = true
    --game.map_settings.enemy_evolution.destroy_factor = 0
    --game.map_settings.enemy_evolution.time_factor = 0
    --game.map_settings.enemy_evolution.pollution_factor = 0
end

local function do_init_surface()
    if not global.init_phase then
        game.print('surface init start')
        local surface = create_surface()
        view_starting_area(surface)
        init_map_settings()
        global.init_phase = INIT_PHASE_SET_SPAWN
        game.print('surface init completed')
    end
end

local function on_player_joined_game(event)
    --do_init_surface(event)
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


-- teleport player and set spawn location


local function teleport_players(surface)
    local spawn_position_x = -76
    local pos = surface.find_non_colliding_position("player", { spawn_position_x + 1, 4 }, 50, 1)
    game.forces["player"].set_spawn_position(pos, surface)
    for _, player in pairs(game.connected_players) do
        local pos = surface.find_non_colliding_position("player", { spawn_position_x + 1, 4 }, 50, 1)
        player.teleport(pos, surface)
    end
end

local function on_chunk_generated(event)
    if global.init_phase == INIT_PHASE_SET_SPAWN then
        if event.surface and event.surface.name == SURVIVAL_IN_POLLUTION then
            teleport_players(event.surface)
            --delete_other_surfaces()
            global.init_phase = INIT_PHASE_COMPLETED
        end
    end
end

Event.register(Event.core_events.init, do_init_surface)
--event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.register(defines.events.on_chunk_generated, on_chunk_generated)
