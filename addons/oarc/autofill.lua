require 'stdlib/event/event'

--------------------------------------------------------------------------------
-- Autofill Stuff
--------------------------------------------------------------------------------

-- Transfer Items Between Inventory
-- Returns the number of items that were successfully transferred.
-- Returns -1 if item not available.
-- Returns -2 if can't place item into destInv (ERROR)
local function TransferItems(srcInv, destEntity, itemStack)
        -- Check if item is in srcInv
        if (srcInv.get_item_count(itemStack.name) == 0) then
                return -1
        end

        -- Check if can insert into destInv
        if (not destEntity.can_insert(itemStack)) then
                return -2
        end

        -- Insert items
        local itemsRemoved = srcInv.remove(itemStack)
        itemStack.count = itemsRemoved
        return destEntity.insert(itemStack)
end

-- Attempts to transfer at least some of one type of item from an array of items.
-- Use this to try transferring several items in order
-- It returns once it successfully inserts at least some of one type.
local function TransferItemMultipleTypes(srcInv, destEntity, itemNameArray, itemCount)
        local ret = 0
        for _,itemName in pairs(itemNameArray) do
                ret = TransferItems(srcInv, destEntity, {name=itemName, count=itemCount})
                if (ret > 0) then
                        return ret -- Return the value succesfully transferred
                end
        end
        return ret -- Return the last error code
end

-- Autofills a turret with ammo
local function AutofillTurret(player, turret)
        local mainInv = player.get_inventory(defines.inventory.player_main)

        -- Attempt to transfer some ammo
        local ret = TransferItemMultipleTypes(mainInv, turret, {"uranium-rounds-magazine", "piercing-rounds-magazine", "firearm-magazine"}, AUTOFILL_TURRET_AMMO_QUANTITY)

        -- Check the result and print the right text to inform the user what happened.
        if (ret > 0) then
                -- Inserted ammo successfully
                -- FlyingText("Inserted ammo x" .. ret, turret.position, my_color_red, player.surface)
        elseif (ret == -1) then
                FlyingText("Out of ammo!", turret.position, my_color_red, player.surface)
        elseif (ret == -2) then
                FlyingText("Autofill ERROR! - Report this bug!", turret.position, my_color_red, player.surface)
        end
end

-- Autofills a vehicle with fuel, bullets and shells where applicable
local function AutoFillVehicle(player, vehicle)
        local mainInv = player.get_inventory(defines.inventory.player_main)

        -- Attempt to transfer some fuel
        if ((vehicle.name == "car") or (vehicle.name == "tank") or (vehicle.name == "locomotive")) then
                TransferItemMultipleTypes(mainInv, vehicle, {"nuclear-fuel", "rocket-fuel", "solid-fuel", "coal", "raw-wood"}, 50)
        end

        -- Attempt to transfer some ammo
        if ((vehicle.name == "car") or (vehicle.name == "tank")) then
                TransferItemMultipleTypes(mainInv, vehicle, {"uranium-rounds-magazine", "piercing-rounds-magazine", "firearm-magazine"}, 100)
        end

        -- Attempt to transfer some tank shells
        if (vehicle.name == "tank") then
                TransferItemMultipleTypes(mainInv, vehicle, {"explosive-uranium-cannon-shell", "uranium-cannon-shell", "explosive-cannon-shell", "cannon-shell"}, 100)
        end
end

-- Autofill softmod
local function Autofill(event)
        local player = game.players[event.player_index]
        local eventEntity = event.created_entity

        if (eventEntity.name == "gun-turret") then
                AutofillTurret(player, eventEntity)
        end

        if ((eventEntity.name == "car") or (eventEntity.name == "tank") or (eventEntity.name == "locomotive")) then
                AutoFillVehicle(player, eventEntity)
        end
end

script.on_event(defines.events.on_built_entity, Autofill)

