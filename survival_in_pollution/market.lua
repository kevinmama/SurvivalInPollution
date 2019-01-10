require('stdlib/event/event')

local function refresh_market_offers()
    if not global.market then
        return
    end
    for i = 1, 100, 1 do
        local a = global.market.remove_market_item(1)
        if a == false then
            break
        end
    end

    --local str1 = "Gun Turret Slot for " .. tostring(global.entity_limits["gun-turret"].limit * global.entity_limits["gun-turret"].slot_price)
    --str1 = str1 .. " Coins."
    --
    --local str2 = "Laser Turret Slot for " .. tostring(global.entity_limits["laser-turret"].limit * global.entity_limits["laser-turret"].slot_price)
    --str2 = str2 .. " Coins."
    --
    --local str3 = "Artillery Slot for " .. tostring(global.entity_limits["artillery-turret"].limit * global.entity_limits["artillery-turret"].slot_price)
    --str3 = str3 .. " Coins."
    --
    --local current_limit = 1
    --if global.entity_limits["flamethrower-turret"].limit ~= 0 then current_limit = current_limit + global.entity_limits["flamethrower-turret"].limit end
    --local str4 = "Flamethrower Turret Slot for " .. tostring(current_limit * global.entity_limits["flamethrower-turret"].slot_price)
    --str4 = str4 .. " Coins."
    --
    --local str5 = "Landmine Slot for " .. tostring(math.ceil((global.entity_limits["land-mine"].limit / 3) * global.entity_limits["land-mine"].slot_price))
    --str5 = str5 .. " Coins."

    local market_items = {
        --{price = {}, offer = {type = 'nothing', effect_description = str1}},
        --{price = {}, offer = {type = 'nothing', effect_description = str2}},
        --{price = {}, offer = {type = 'nothing', effect_description = str3}},
        --{price = {}, offer = {type = 'nothing', effect_description = str4}},
        --{price = {}, offer = {type = 'nothing', effect_description = str5}},
        { price = { { "raw-fish", 1 } }, offer = { type = 'give-item', item = "coin", count = 4 } },
        { price = { { "coin", 5 } }, offer = { type = 'give-item', item = "raw-fish", count = 1 } },
        { price = { { "coin", 1 } }, offer = { type = 'give-item', item = 'raw-wood', count = 8 } },
        { price = { { "coin", 8 } }, offer = { type = 'give-item', item = 'grenade', count = 1 } },
        { price = { { "coin", 32 } }, offer = { type = 'give-item', item = 'cluster-grenade', count = 1 } },
        { price = { { "coin", 1 } }, offer = { type = 'give-item', item = 'land-mine', count = 1 } },
        { price = { { "coin", 80 } }, offer = { type = 'give-item', item = 'car', count = 1 } },
        { price = { { "coin", 1200 } }, offer = { type = 'give-item', item = 'tank', count = 1 } },
        { price = { { "coin", 3 } }, offer = { type = 'give-item', item = 'cannon-shell', count = 1 } },
        { price = { { "coin", 7 } }, offer = { type = 'give-item', item = 'explosive-cannon-shell', count = 1 } },
        { price = { { "coin", 50 } }, offer = { type = 'give-item', item = 'gun-turret', count = 1 } },
        { price = { { "coin", 300 } }, offer = { type = 'give-item', item = 'laser-turret', count = 1 } },
        { price = { { "coin", 450 } }, offer = { type = 'give-item', item = 'artillery-turret', count = 1 } },
        { price = { { "coin", 10 } }, offer = { type = 'give-item', item = 'artillery-shell', count = 1 } },
        { price = { { "coin", 25 } }, offer = { type = 'give-item', item = 'artillery-targeting-remote', count = 1 } },
        { price = { { "coin", 1 } }, offer = { type = 'give-item', item = 'firearm-magazine', count = 1 } },
        { price = { { "coin", 4 } }, offer = { type = 'give-item', item = 'piercing-rounds-magazine', count = 1 } },
        { price = { { "coin", 2 } }, offer = { type = 'give-item', item = 'shotgun-shell', count = 1 } },
        { price = { { "coin", 6 } }, offer = { type = 'give-item', item = 'piercing-shotgun-shell', count = 1 } },
        { price = { { "coin", 30 } }, offer = { type = 'give-item', item = "submachine-gun", count = 1 } },
        { price = { { "coin", 250 } }, offer = { type = 'give-item', item = 'combat-shotgun', count = 1 } },
        { price = { { "coin", 450 } }, offer = { type = 'give-item', item = 'flamethrower', count = 1 } },
        { price = { { "coin", 25 } }, offer = { type = 'give-item', item = 'flamethrower-ammo', count = 1 } },
        { price = { { "coin", 125 } }, offer = { type = 'give-item', item = 'rocket-launcher', count = 1 } },
        { price = { { "coin", 2 } }, offer = { type = 'give-item', item = 'rocket', count = 1 } },
        { price = { { "coin", 7 } }, offer = { type = 'give-item', item = 'explosive-rocket', count = 1 } },
        { price = { { "coin", 7500 } }, offer = { type = 'give-item', item = 'atomic-bomb', count = 1 } },
        { price = { { "coin", 325 } }, offer = { type = 'give-item', item = 'railgun', count = 1 } },
        { price = { { "coin", 8 } }, offer = { type = 'give-item', item = 'railgun-dart', count = 1 } },
        { price = { { "coin", 40 } }, offer = { type = 'give-item', item = 'poison-capsule', count = 1 } },
        { price = { { "coin", 4 } }, offer = { type = 'give-item', item = 'defender-capsule', count = 1 } },
        { price = { { "coin", 10 } }, offer = { type = 'give-item', item = 'light-armor', count = 1 } },
        { price = { { "coin", 125 } }, offer = { type = 'give-item', item = 'heavy-armor', count = 1 } },
        { price = { { "coin", 350 } }, offer = { type = 'give-item', item = 'modular-armor', count = 1 } },
        { price = { { "coin", 1500 } }, offer = { type = 'give-item', item = 'power-armor', count = 1 } },
        { price = { { "coin", 12000 } }, offer = { type = 'give-item', item = 'power-armor-mk2', count = 1 } },
        { price = { { "coin", 50 } }, offer = { type = 'give-item', item = 'solar-panel-equipment', count = 1 } },
        { price = { { "coin", 2250 } }, offer = { type = 'give-item', item = 'fusion-reactor-equipment', count = 1 } },
        { price = { { "coin", 100 } }, offer = { type = 'give-item', item = 'battery-equipment', count = 1 } },
        { price = { { "coin", 200 } }, offer = { type = 'give-item', item = 'energy-shield-equipment', count = 1 } },
        { price = { { "coin", 750 } }, offer = { type = 'give-item', item = 'personal-laser-defense-equipment', count = 1 } },
        { price = { { "coin", 175 } }, offer = { type = 'give-item', item = 'exoskeleton-equipment', count = 1 } },
        { price = { { "coin", 125 } }, offer = { type = 'give-item', item = 'night-vision-equipment', count = 1 } },
        { price = { { "coin", 200 } }, offer = { type = 'give-item', item = 'belt-immunity-equipment', count = 1 } },
        { price = { { "coin", 250 } }, offer = { type = 'give-item', item = 'personal-roboport-equipment', count = 1 } },
        { price = { { "coin", 20 } }, offer = { type = 'give-item', item = 'construction-robot', count = 1 } }
    }

    for _, item in pairs(market_items) do
        global.market.add_market_item(item)
    end
end


local function is_game_surface(event)
    local surface = game.surfaces[SURVIVAL_IN_POLLUTION]
    if not surface then
        return false
    end
    return surface.name == event.surface.name
end

local function do_market_init(event)
    local area = event.area
    local left_top = area.left_top

    if left_top.x <= -196 then
        if not global.market then
            game.print('market generation')
            local surface = game.surfaces[SURVIVAL_IN_POLLUTION]
            local spawn_position_x = -76
            local pos = surface.find_non_colliding_position("market", { spawn_position_x, 0 }, 50, 1)
            global.market = surface.create_entity({ name = "market", position = pos, force = "player" })
            global.market.minable = false
            refresh_market_offers()

            game.forces['player'].chart(surface, {
                { pos.x - 200, pos.y - 200 },
                { pos.x + 200, pos.y + 200 }
            })
            --teleport_players_to_market(surface)
        end
    end
end

local function on_chunk_generated(event)
    if is_game_surface(event) then
        do_market_init(event)
    end
end

Event.register(defines.events.on_chunk_generated, on_chunk_generated)

