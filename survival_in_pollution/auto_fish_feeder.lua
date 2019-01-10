-- auto eat fish to restore health

require 'stdlib/event/event'
require 'stdlib/event/gui'

global.auto_fish_feeders = {}

local function AutoFishFeeder(data)
    local self = {
        player_index = player_index,
        enabled = true
    }
    for k, v in pairs(data) do
        self[k] = v
    end

    local function enable(enabled)
        self.enabled = enabled
    end

    local function player()
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
        return player.character and player.character.health < player.character.prototype.max_health - 100
    end

    local function try_feed()
        local player = player()
        if self.enabled and is_player_not_healthy(player) then
            local inventory = get_inventory_has_enough_fish(player)
            if inventory then
                feed(player, inventory)
            end
        end
    end

    return {
        data = self,
        player = player,
        enable = enable,
        try_feed = try_feed
    }
end

local function AutoFishFeederGUI(feeder)

    local name = 'auto_fish_feeder_checkbox'

    local function register_event()
        Gui.on_checked_state_changed(name, function(event)
            global.auto_fish_feeders[event.player_index].enable(event.element.state)
        end)
    end

    local function create()
        local player = feeder.player()
        -- contribute to global setting dropdown button later
        local frame = player.gui.top.add({ type = "frame", name = "auto_fish_feeder_frame", caption = "auto_use_fish"})
        frame.style.minimal_height = 80
        frame.add({ type = "checkbox", name = name, state = feeder.data.enabled })
        register_event()
    end

    local function load()
        -- gui has created
        register_event()
    end

    return {
        create = create,
        load = load
    }
end

Event.register(defines.events.on_player_created, function(event)
    -- 玩家只会创建一次，载入不会重新创建玩家。但联机玩可以通过玩家加入事件来初始化
    local feeder = AutoFishFeeder({
        player_index = event.player_index
    })
    global.auto_fish_feeders[event.player_index] = feeder
    AutoFishFeederGUI(feeder).create()
end)

--Event.register(defines.events.on_player_joined_game, function(event)
--    log('on player ' .. event.player_index .. ' joined game')
--    -- 读档不会重新触发这个事件
--end)
--
--Event.register(Event.core_events.init, function()
--    log('on init')
----    读档时也不会触发。那读档时怎么为 gui 重新初始化？难道只能通通使用 global 来处理
--end)

-- 多人联机时，用 join 事件可能会更好一些

Event.register(Event.core_events.load, function()
    -- 这个时候还没有 game 对象
    for _, feeder in ipairs(global.auto_fish_feeders) do
        local feeder = AutoFishFeeder(feeder.data)
        global.auto_fish_feeders[_] = feeder
        AutoFishFeederGUI(feeder).load()
    end
end)

Event.register(defines.events.on_tick, function(event)
    if event.tick % 60 == 0 then
        for _, player in ipairs(game.connected_players) do
            local feeder = global.auto_fish_feeders[player.index]
            if feeder then
                feeder.try_feed()
            end
        end
    end
end)

