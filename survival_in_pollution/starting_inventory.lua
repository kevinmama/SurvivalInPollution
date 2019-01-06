local event = require('utils.event')


local function on_player_created(event)
    local player = game.players[event.player_index]
    player.insert{name="iron-plate", count=8}
    player.insert{name="pistol", count=1}
    player.insert{name="firearm-magazine", count=10}
    player.insert{name="burner-mining-drill", count = 1}
    player.insert{name="stone-furnace", count = 1}
    player.insert{name="raw-fish", count=100}
    if DEBUG then
        player.insert{name='coin', count=20000}
    end
end

local function on_player_respawned(event)
    local player = game.players[event.player_index]
    player.insert{name="pistol", count=1}
    player.insert{name="firearm-magazine", count=10}
    player.insert{name="raw-fish", count=5}
end

event.add(defines.events.on_player_created, on_player_created)
event.add(defines.events.on_player_respawned, on_player_respawned)



