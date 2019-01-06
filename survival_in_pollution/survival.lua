local event = require('utils.event')

local POLLUTION_THREADSOLD = 1000

-- forces: player, enemy, neutral

local function per_second(t)
    return t % 60 == 0
end

local function get_pollution(player)
    return player.surface.get_pollution(player.position)
end

local function out_of_pollution(player)
    return get_pollution(player) < POLLUTION_THREADSOLD
end

local function get_damage_by_poison(player)
    return (POLLUTION_THREADSOLD - get_pollution(player))/100
end

local function damage_to_player(player)
    if player.character then
        player.character.damage(get_damage_by_poison(player), "neutral", 'poison')
    end
end

local function handle_player_out_of_pollution(event)
    if per_second(event.tick) then
        for index, player in pairs(game.connected_players) do
            if out_of_pollution(player) then
                damage_to_player(player)
            end
        end
    end
end

event.add(defines.events.on_tick, handle_player_out_of_pollution)
