-- auto eat fish to restore health

global.auto_fish_feeders = {}

local function AutoFishFeeder(data)
    local self = {
        player_index = player_index,
        enabled = true
    }
    for k,v in pairs(data) do self[k] = v end

    local function enable(enabled)
        self.enabled = enabled
    end

    local function get_player()
        return game.players[self.player_index]
    end

    local function has_enough_fish_of_inventory(inventory)
        return inventory.get_item_count("raw-fish") > 0
    end

    local function get_inventory_has_enough_fish(player)
        for _, inv in ipairs({
            player.get_inventory(defines.inventory.player_quickbar),
            player.get_inventory(defines.inventory.player_main)
        }) do
            if has_enough_fish_of_inventory(inv) then
                return inv
            end
        end
        return nil
    end

    local function feed(player, inventory)
        local stack = inventory.find_item_stack('raw-fish')
        stack.count = stack.count - 1
        -- how to use capsule correctly?
        --script.raise_event(defines.events.on_player_used_capsule, {
        --    player_index = player.index,
        --    item = stack.prototype,
        --    position = player.position
        --})

        player.character.health = player.character.health + 80
    end

    local function is_player_not_healthy(player)
        return player.character.health < player.character.prototype.max_health - 100
    end

    local function try_feed()
        local player = get_player()
        if self.enabled and is_player_not_healthy(player) then
            local inventory = get_inventory_has_enough_fish(player)
            if inventory then
                feed(player, inventory)
            end
        end
    end

    return {
        data = self,
        enable = enable,
        try_feed = try_feed
    }
end

local Event = require('utils.event')

Event.on_load(function()
    for _, feeder in ipairs(global.auto_fish_feeders) do
        global.auto_fish_feeders[_] = AutoFishFeeder(feeder.data)
    end
end)

Event.add(defines.events.on_player_created, function(event)
    global.auto_fish_feeders[event.player_index] = AutoFishFeeder({
        player_index = event.player_index
    })
end)

Event.add(defines.events.on_tick, function(event)
    if event.tick % 60 == 0 then
        for _, player in ipairs(game.connected_players) do
            local feeder = global.auto_fish_feeders[player.index]
            if feeder then
                feeder.try_feed()
            end
        end
    end
end)
