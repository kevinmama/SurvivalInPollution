require 'stdlib/event/event'

local function welcome(event)
    local player = game.players[event.player_index]
    player.force.chart(player.surface, { { player.position.x - 200, player.position.y - 200 }, { player.position.x + 200, player.position.y + 200 } })
    player.print({ "msg-intro" })
end

Event.register(defines.events.on_player_created, welcome)
