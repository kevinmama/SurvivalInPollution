require 'stdlib/event/event'

local function add_pollution_label_gui(event)
    local player = game.players[event.player_index]
    local frame = player.gui.top.add({ type = 'frame', name = 'pollution_frame', caption = 'pollution: 0'})
    frame.style.minimal_height = 80
    local bar = frame.add { type = "progressbar", name = "pollution_progress"}
    bar.value = 0
    bar.style.color = {r=1}
end

local function update_progress_bar_value(player, pollution)
    local value
    if (pollution <= POLLUTION_DAMAGE_THRESHOLD) then
        value = pollution / POLLUTION_DAMAGE_THRESHOLD
    else
        value = 1
    end
    player.gui.top["pollution_frame"]["pollution_progress"].value = value
end

local function update_pollution_label_gui_for_player(player)
    local pollution = player.surface.get_pollution(player.position)
    player.gui.top.pollution_frame.caption = "pollution: " .. string.format("%.f", pollution)
    update_progress_bar_value(player, pollution)
end

local function update_on_position_changed(event)
    local player = game.players[event.player_index]
    update_pollution_label_gui_for_player(player)
end

local function update_on_tick(event)
    if event.tick % 60 == 0 then
        for _, player in pairs(game.connected_players) do
            update_pollution_label_gui_for_player(player)
        end
    end
end

Event.register(defines.events.on_player_created, add_pollution_label_gui)
Event.register(defines.events.on_player_changed_position, update_on_position_changed)
Event.register(defines.events.on_tick, update_on_tick)

