-- 在污染下，超过能承受的阀值开始受到伤害。时间越长受伤越大
-- 希望能平滑前、中、后期的效果。
-- 前期污染少，但能力弱。
-- 阀值可以升级？

require 'stdlib/event/event'

-- 尝试用 global_id 来索引数据
--local function PollutionKiller(player_index)
--
--    local id = "pollution_killer_" .. player_index
--    if not global[id] then
--        global[id] = {
--            threshold = 1000
--        }
--    end
--end



-- forces: player, enemy, neutral

local function per_second(t)
    return t % 60 == 0
end

local function get_pollution(player)
    return player.surface.get_pollution(player.position)
end

local function in_pollution(player)
    return get_pollution(player) > POLLUTION_DAMAGE_THRESHOLD
end

local function get_damage_by_poison(player)
    return (get_pollution(player) - POLLUTION_DAMAGE_THRESHOLD) * POLLUTION_DAMAGE_MULTIPLIER
end

local function damage_to_player(player)
    if player.character then
        player.character.damage(get_damage_by_poison(player), "neutral", 'poison')
    end
end

local function handle_player_in_pollution(event)
    if per_second(event.tick) then
        for _, player in ipairs(game.connected_players) do
            if in_pollution(player) then
                damage_to_player(player)
            end
        end
    end
end

Event.register(defines.events.on_tick, handle_player_in_pollution)

